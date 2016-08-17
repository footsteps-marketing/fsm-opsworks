#
# Cookbook Name:: fsm-opsworks
# Recipe:: deploy
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

require 'uri'
require 'net/http'
require 'net/https'

le_master_instance = nil

#
# Get the LetsEncrypt Master Instance Info
# 
search("aws_opsworks_layer").each do |layer|
    if layer[:shortname] != 'le-master'
        next
    end
    Chef::Log.info("**************** FOUND LE MASTER LAYER: #{layer[:layer_id]}")

    search('aws_opsworks_instance').each do |instance|
        if instance[:layer_ids].include? layer[:layer_id]
            le_master_instance = instance
        end
    end
end

command = search('aws_opsworks_command').first
search("aws_opsworks_app").each do |app|
    
    # Bail out if not deploying this app
    if app['deploy'] == false
        next
    end

    # Set the deploy user
    # @todo -- do this programmatically?
    deploy_user = 'www-data'
    deploy_group = 'www-data'

    # Get a nice numeric string for the current version and set paths accordingly
    current_revision = command['sent_at'].delete("^0-9")
    deploy_root = "/srv/www/#{app['shortname']}/#{current_revision}"
    server_root = "/srv/www/#{app['shortname']}/current"
    Chef::Log.info("**************** Deploying #{app['shortname']} to #{deploy_root}")

    
    # Create the deploy directory
    directory "#{deploy_root}" do
        owner deploy_user
        group deploy_group
        mode '0775'
        recursive true
        action :create
    end

    
    # deploy the app from its source
    # @todo handle non-git sources?
    if app['app_source']['type'] == 'git'

        # Set up folders and key files
        # as required for private key type deployments
        key_path = "/var/www/.ssh/#{app['shortname']}_rsa"
        wrapper_path = "/tmp/wrappers/#{app['shortname']}.sh"
        
        directory "/var/www/.ssh" do
            owner deploy_user
            group deploy_group
            mode '0700'
            recursive true
            action :create
        end

        directory "/tmp/wrappers" do
            owner deploy_user
            group deploy_group
            mode '0755'
            recursive true
            action :create
        end

        # Set up keys if needed
        if app['app_source']['ssh_key'] != 'null'
            file "#{key_path}" do
                owner deploy_user
                group deploy_group
                mode "0600"
                content "#{app['app_source']['ssh_key']}"
            end
            file "#{wrapper_path}" do
                owner deploy_user
                group deploy_group
                mode "0755"
                content "#!/bin/sh\nexec /usr/bin/ssh -o StrictHostKeyChecking=no -i #{key_path} \"$@\""
            end
        end

        
        # deploy the app
        git "#{deploy_root}" do
            revision app['app_source']['revision']
            repository app['app_source']['url']
            user deploy_user
            group deploy_group
            if app['app_source']['ssh_key'] != 'null'
                ssh_wrapper "#{wrapper_path}"
            end
            action :sync
        end
    end

    
    # Write our lil' domain getter script out
    template "#{deploy_root}/get-mapped-domains.php" do
        source "get-mapped-domains.php.erb"
        mode 0700
        group "root"
        owner "root"
    end



    # Write out the wordpress multisite snippet
    template "/etc/nginx/snippets/wordpress.conf" do
        source "wordpress.conf.erb"
        mode 0644
        owner "root"
        group "root"

        variables(
            :app => (app rescue nil),
        )
    end

    
    # 
    # Write out nginx.conf stuff for our app
    # 
    template "/etc/nginx/sites-available/#{app['shortname']}.conf" do
        source "site.conf.erb"
        mode 0644
        owner "root"
        group "root"

        variables(
            :logbase => '/var/log/nginx',
            :app => (app rescue nil),
            :ssl => node[:letsencrypt][:get_certificates]
        )
    end

    # Clean up old linked confs...
    Dir.foreach('/etc/nginx/sites-enabled') do |item|
        next if item == '.' or item == '..'
        link "/etc/nginx/sites-enabled/#{item}" do
            action :delete
            only_if "test -L '/etc/nginx/sites-enabled/#{item}'"
        end
    end

    # Link the new confs...
    link "/etc/nginx/sites-enabled/#{app['shortname']}.conf" do
        to "/etc/nginx/sites-available/#{app['shortname']}.conf"
        if node[:letsencrypt][:get_certificates] == false
            notifies :restart, "service[nginx]", :delayed
        end
    end

    #
    # Now write out the domain confs...
    # 
    Domains.get(deploy_root, node[:wordpress][:multisite][:domain_current_site]) do |domains|
        domains.each do |domain|
            Chef::log.info("***** Mapping Domain: #{domain}")
            template "/etc/nginx/sites-available/#{domain}.conf" do
                source "site.conf.erb"
                mode 0644
                owner "root"
                group "root"

                variables(
                    :logbase => '/var/log/nginx',
                    :app => (app rescue nil),
                    :url => (domain rescue nil),
                    :ssl => node[:letsencrypt][:get_certificates]
                )
            end

            link "/etc/nginx/sites-enabled/#{domain}.conf" do
                to "/etc/nginx/sites-available/#{domain}.conf"
                if node[:letsencrypt][:get_certificates] == false
                    notifies :restart, "service[nginx]", :delayed
                end
            end
        end
    end


    # Get or generate salts
    if node['wordpress']['salt'] == false then
        uri = URI.parse("https://api.wordpress.org/secret-key/1.1/salt/")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        keys = response.body
    else
        keys = node['wordpress']['salt']
    end



    # Get database info
    db_user = nil
    db_password = nil
    db_host = nil
    app_db_arn = app[:data_sources].first[:arn]

    search("aws_opsworks_rds_db_instance").each do |db|
        Chef::Log.info("******** Checking database #{db['rds_db_instance_arn']}")
        Chef::Log.info("********  against database #{app_db_arn}")

        if db['rds_db_instance_arn'] == app_db_arn
            db_user = db[:db_user]
            db_password = db[:db_password]
            db_host = db[:address]
        end
    end

    # Write out wp-config.php
    template "#{deploy_root}/wp-config.php" do
        source "wp-config.php.erb"
        mode 0660
        owner deploy_user
        group deploy_group
        
        variables(
            :database   => (app['data_sources'].first['database_name'] rescue nil),
            :user       => (db_user rescue nil),
            :password   => (db_password rescue nil),
            :host       => (db_host rescue nil),
            :keys       => (keys rescue nil)
        )
    end


    # Clean up any excluded plugins
    exclude_plugins = node['wordpress']['exclude_plugins']
    exclude_themes = node['wordpress']['exclude_themes']

    exclude_plugins.each do |plugin|
        Chef::Log.debug("Deleting #{deploy_root}/current/wp-content/plugins/#{plugin}")
        directory "#{deploy_root}/current/wp-content/plugins/#{plugin}" do
            recursive true
            action :delete
        end
    end

    exclude_themes.each do |theme|
        Chef::Log.debug("#{deploy_root}/current/wp-content/themes/#{theme}")
        directory "#{deploy_root}/current/wp-content/themes/#{theme}" do
            recursive true
            action :delete
        end
    end


    # Make the minifier happy
    directory "#{deploy_root}/current/wp-content/plugins/bwp-minify/cache" do
        recursive true
        owner deploy_user
        group deploy_group
        mode '0775'
        action :create
    end
    

    # Link the new deployment up
    link "#{server_root}" do
        to deploy_root
    end

    # Restart nginx for good measure
    service "nginx" do
        action :nothing
    end
end