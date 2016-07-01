#
# Cookbook Name:: fsm-opsworks
# Recipe:: deploy
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

require 'uri'
require 'net/http'
require 'net/https'

command = search('aws_opsworks_command').first
search("aws_opsworks_app").each do |app|
    
    # Bail out if not deploying this app
    if app['deploy'] === false
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


    # Write out the wordpress multisite snippet
    template "/etc/nginx/snippets/wordpress-multisite.conf" do
        source "wordpress-multisite.conf.erb"
        mode 0644
        owner "root"
        group "root"

        variables(
            :app => (app rescue nil),
        )
    end

    
    # Write out nginx.conf stuff for domains
    app['domains'].each do |domain|
        Chef::Log.info("**************** Writing config for #{domain}")
        template "/etc/nginx/sites-available/#{domain}.conf" do
            source "site.conf.erb"
            mode 0644
            owner "root"
            group "root"

            variables(
                :app => (app rescue nil),
                :url => (domain rescue nil)
            )
        end

        link "/etc/nginx/sites-enabled/#{domain}.conf" do
            to "/etc/nginx/sites-available/#{domain}.conf"
        end
    end

    if node['wordpress']['salt'] == false then
        uri = URI.parse("https://api.wordpress.org/secret-key/1.1/salt/")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        keys = response.body
    else
        keys = node['wordpress']['wp_config']['salt']
    end

    search("aws_opsworks_rds_db_instance").each do |db|
        if db['rds_db_instance_arn'] == app['data_sources']['arn']
            template "#{deploy_root}/wp-config.php" do
                source "wp-config.php.erb"
                mode 0660
                owner deploy_owner
                group deploy_group
                
                variables(
                    :database   => (app['data_sources']['staging_wp_env'] rescue nil),
                    :user       => (db[:db_user] rescue nil),
                    :password   => (db[:db_password] rescue nil),
                    :host       => (db[:address] rescue nil),
                    :keys       => (keys rescue nil)
                )
            end
        end
    end

    link "#{server_root}" do
        to deploy_root
    end

    service "nginx" do
        action :restart
    end
end