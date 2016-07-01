#
# Cookbook Name:: fsm-opsworks
# Recipe:: deploy
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

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

    Chef::Log.info("*********** DATA SOURCES HERE ************")
    Chef::Log.info(YAML::dump(app['data_sources']))

=begin
    @todo Figure out data sources for the database and wp-config code below:

    template "#{deploy_root}/wp-config.php" do
        source "wp-config.php.erb"
        mode 0660
        owner deploy_owner
        group deploy_group
        
        variables(
            :database   => (deploy[:database][:database] rescue nil),
            :user       => (deploy[:database][:username] rescue nil),
            :password   => (deploy[:database][:password] rescue nil),
            :host       => (deploy[:database][:host] rescue nil),
            :keys       => (keys rescue nil)
        )
    end
=end
    

    link "#{server_root}" do
        to deploy_root
    end

    service "nginx" do
        action :restart
    end
end