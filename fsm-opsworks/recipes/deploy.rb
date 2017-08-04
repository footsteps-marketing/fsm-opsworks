#
# Cookbook Name:: fsm-opsworks
# Recipe:: deploy
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

# Notes
# - Template sources are all relative to this
#   cookbook's `templates/default` directory

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
    revision_root = "/srv/www/#{app['shortname']}"
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
            notifies :create, "template[#{deploy_root}/wordpress/wp-config.php]", :immediately
            if app['app_source']['ssh_key'] != 'null'
                ssh_wrapper "#{wrapper_path}"
            end
            action :sync
        end
    end


    # deploy the app from its source
    if app['app_source']['type'] == 's3'

        package "unzip" do
          retries 2
        end

        s3_bucket, s3_key, base_url = OpsWorks::SCM::S3.parse_uri(app[:app_source][:url])
        
        tmp_download_location = "/tmp/fsm-wordpress.tar.gz"

        s3_file "#{tmp_download_location}" do
            bucket s3_bucket
            remote_path s3_key
            s3_url base_url
            aws_access_key_id app[:app_source][:user]
            aws_secret_access_key app[:app_source][:password]
            owner deploy_user
            group deploy_group
            mode "0600"
            action :create
        end

        tar_extract "#{tmp_download_location}" do
            target_dir "#{deploy_root}"
            creates "#{deploy_root}/wordpress"
            notifies :create, "template[#{deploy_root}/wordpress/wp-config.php]", :immediately
            user deploy_user
            group deploy_group
            action :extract_local
        end
    end


    bash "update_php_ini" do
        if command['type'] == 'deploy'
            action :run
        else
            action :nothing
            subscribes :run, 'package[php-fpm]', :immediately
        end
        user "root"
        code <<-EOH
            sed -i \
                -e 's/^upload_max_filesize.*$/upload_max_filesize=#{node[:wordpress][:max_upload_size]}/g' \
                -e 's/^post_max_size.*$/post_max_size=#{node[:wordpress][:max_upload_size]}/g' \
                -e 's/^max_execution_time.*$/max_execution_time=#{node[:wordpress][:max_execution_time]}/g' \
                /etc/php/7.0/fpm/php.ini
            EOH
    end
    
    
    # Create SSL cert directories
    directory "/etc/ssl-manager" do
        owner "ssl-manager"
        group "root"
        mode '0755'
        recursive true
        action :create
    end
    
    directory "/etc/ssl-manager/certs" do
        owner "ssl-manager"
        group "root"
        mode '0755'
        recursive true
        action :create
    end
    
    directory "/etc/ssl-manager/private" do
        owner "ssl-manager"
        group "root"
        mode '0700'
        recursive true
        action :create
    end
    
    
    # Create dhparam certificate
    execute "openssl_dhparam" do
        command 'openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048'
        creates '/etc/ssl/certs/dhparam.pem'
    end


    # Write out the php-fpm pool conf
    template "/etc/php/7.0/fpm/pool.d/www.conf" do
        if command['type'] == 'deploy'
            action :create
        else
            action :nothing
            subscribes :create, 'package[php-fpm]', :immediately
        end
        source "etc/php/7.0/fpm/pool.d/www.conf"
        mode 0644
        owner "root"
        group "root"
    end


    # Write out the wordpress multisite snippet
    template "/etc/nginx/snippets/wordpress.conf" do
        if command['type'] == 'deploy'
            action :create
        else
            action :nothing
            subscribes :create, 'package[nginx]', :immediately
        end
        source "etc/nginx/snippets/wordpress.conf.erb"
        mode 0644
        owner "root"
        group "root"

        variables(
            :app => (app rescue nil),
        )
    end

    # Write out the wordfence snippet
    template "/etc/nginx/snippets/wordfence.conf" do
        if command['type'] == 'deploy'
            action :create
        else
            action :nothing
            subscribes :create, 'package[nginx]', :immediately
        end
        source "etc/nginx/snippets/wordfence.conf.erb"
        mode 0644
        owner "root"
        group "root"
    end

    
    # 
    # Write out nginx.conf stuff for our app
    # 
    template "/etc/nginx/sites-available/#{app['shortname']}.conf" do
        if command['type'] == 'deploy'
            action :create
        else
            action :nothing
            subscribes :create, 'package[nginx]', :immediately
        end
        source "etc/nginx/sites-available/default.conf.erb"
        mode 0644
        owner "root"
        group "root"

        variables(
            :server_root => server_root,
            :logbase => '/var/log/nginx',
            :app => (app rescue nil)
        )
    end

    
    # 
    # Write out template nginx conf file for SSL domain conf creation
    # 
    template "/etc/nginx/sites-available/template.conf" do
        if command['type'] == 'deploy'
            action :create
        else
            action :nothing
            subscribes :create, 'package[nginx]', :immediately
        end
        source "etc/nginx/sites-available/template.conf.erb"
        mode 0644
        owner "root"
        group "root"

        variables(
            :server_root => server_root,
            :logbase => '/var/log/nginx',
            :app => (app rescue nil)
        )
    end
    
    template "/etc/nginx/nginx.conf" do
      if command['type'] == 'deploy'
        action :create
      else
        action :nothing
        subscribes :create, 'package[nginx]', :immediately
      end
      
      source "etc/nginx/nginx.conf.erb"
      mode 0644
      owner "root"
      group "root"
    end

    # Create the app's symlink
    link "/etc/nginx/sites-enabled/#{app['shortname']}.conf" do
        to "/etc/nginx/sites-available/#{app['shortname']}.conf"

        if command['type'] == 'deploy'
            action :create
        else
            action :nothing
            subscribes :create, "template[/etc/nginx/sites-available/#{app['shortname']}.conf", :immediately
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
    template "#{deploy_root}/wordpress/wp-config.php" do
        action :nothing
        source "srv/www/APPNAME/RELEASETIME/wp-config.php.erb"
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


    # Write out bwp-minify config
    template "#{deploy_root}/wordpress/wp-content/plugins/bwp-minify/min/config.php" do
        action :nothing
        subscribes :create, "template[#{deploy_root}/wordpress/wp-config.php]", :immediately
        source "srv/www/APPNAME/RELEASETIME/bwp-minify-config.php.erb"
        mode 0660
        owner deploy_user
        group deploy_group
    end


    # Write our lil' domain getter script out
    template "#{deploy_root}/get-mapped-domains.php" do
        action :nothing
        subscribes :create, "template[#{deploy_root}/wordpress/wp-config.php]", :immediately
        source "srv/www/APPNAME/RELEASETIME/get-mapped-domains.php.erb"
        mode 0700
        group "root"
        owner "root"
    end


    # Clean up any excluded plugins and themes
    exclude_plugins = node['wordpress']['exclude_plugins']
    exclude_themes = node['wordpress']['exclude_themes']

    exclude_plugins.each do |plugin|
        Chef::Log.debug("Deleting #{deploy_root}/wordpress/wp-content/plugins/#{plugin}")
        directory "#{deploy_root}/wordpress/wp-content/plugins/#{plugin}" do
            recursive true
            action :nothing
            subscribes :delete, "template[#{deploy_root}/wordpress/wp-config.php]", :immediately
        end
    end

    exclude_themes.each do |theme|
        Chef::Log.debug("#{deploy_root}/wordpress/wp-content/themes/#{theme}")
        directory "#{deploy_root}/wordpress/wp-content/themes/#{theme}" do
            recursive true
            action :nothing
            subscribes :delete, "template[#{deploy_root}/wordpress/wp-config.php]", :immediately
        end
    end


    # Make the minifier happy
    directory "#{deploy_root}/wordpress/wp-content/plugins/bwp-minify/cache" do
        recursive true
        owner deploy_user
        group deploy_group
        mode '0775'
        action :nothing
        subscribes :create, "template[#{deploy_root}/wordpress/wp-config.php]", :immediately
    end
    

    # Link the new deployment up
    link "#{server_root}" do
        to deploy_root
        action :nothing
        subscribes :create, "template[#{deploy_root}/wordpress/wp-config.php]", :immediately
    end


    # Clean up old deployments (latest 5 persist)
    bash "cleanup" do
        action :nothing
        cwd revision_root
        subscribes :run, "link[#{server_root}]", :immediately
        code "ls -tp | grep '/$' | tail -n +6 | xargs -I {} rm -rf -- {}"
    end


    # Restart nginx for good measure
    service "nginx" do
        action :nothing
        subscribes :restart, "link[#{server_root}]", :immediately
    end

    service "php7.0-fpm" do
        action :nothing
        subscribes :restart, "link[#{server_root}]", :immediately
    end
end
