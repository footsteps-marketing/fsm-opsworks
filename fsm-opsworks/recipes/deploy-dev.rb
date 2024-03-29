#
# Cookbook Name:: fsm-opsworks
# Recipe:: deploy
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

require 'uri'
require 'net/http'
require 'net/https'

search("aws_opsworks_app").each do |app|
    deploy_user = 'www-data'
    deploy_group = 'www-data'
    deploy_root = "/vagrant/"
    server_root = deploy_root
    
    # Write out the php-fpm pool conf
    template "/etc/php/7.0/fpm/pool.d/www.conf" do
        action :nothing
        subscribes :create, 'package[php-fpm]', :immediately
        notifies :restart, 'service[php7.0-fpm]', :delayed
        source "etc/php/7.0/fpm/pool.d/www.conf"
        mode 0644
        owner "root"
        group "root"
    end

    # Write out the wordpress multisite snippet
    template "/etc/nginx/snippets/wordpress.conf" do
        action :nothing
        subscribes :create, 'package[nginx]', :immediately
        notifies :restart, 'service[nginx]', :delayed
        source "etc/nginx/snippets/wordpress.conf.erb"
        mode 0644
        owner "root"
        group "root"

        variables(
            :app => (app rescue nil),
        )
    end


    #
    # Copy self-signed development certificate and key
    #
    directory "/etc/certs/" do
        action :nothing
        subscribes :create, 'package[nginx]', :immediately
        mode 0755
        owner "root"
        group "root"
    end

    template "/etc/certs/devcert.crt" do
        action :nothing
        subscribes :create, 'directory[/etc/certs/]', :immediately
        source "etc/certs/devcert.crt"
        mode 0644
        owner "root"
        group "root"
    end

    template "/etc/certs/devcert.key" do
        action :nothing
        subscribes :create, 'template[/etc/certs/devcert.crt]', :immediately
        source "etc/certs/devcert.key"
        mode 0600
        owner "root"
        group "root"
    end


    # 
    # Write out nginx.conf stuff for our app
    # 
    template "/etc/nginx/sites-available/#{app['shortname']}.conf" do
        action :nothing
        subscribes :create, 'template[/etc/certs/devcert.key]', :immediately
        source "etc/nginx/sites-available/default-dev.conf.erb"
        mode 0644
        owner "root"
        group "root"

        variables(
            :server_root => server_root,
            :logbase => '/vagrant/env/log/nginx',
            :app => (app rescue nil),
            :ssl => node[:letsencrypt][:get_certificates]
        )
    end

    # Clean up old linked confs...
    link "/etc/nginx/sites-enabled/default" do
        action :delete
        notifies :restart, 'service[nginx]', :immediately
        only_if "test -L '/etc/nginx/sites-enabled/default'"
    end

    template "/etc/nginx/nginx.conf" do
        source "etc/nginx/nginx.conf.erb"
        mode 0644
        owner "root"
        group "root"
        subscribes :create, 'package[nginx]', :immediately
        notifies :restart, 'service[nginx]', :delayed
    end

    # Link the new confs...
    link "/etc/nginx/sites-enabled/#{app['shortname']}.conf" do
        to "/etc/nginx/sites-available/#{app['shortname']}.conf"
        action :nothing
        subscribes :create, "template[/etc/nginx/sites-available/#{app['shortname']}.conf]", :immediately
        notifies :restart, 'service[nginx]', :delayed
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
    db_name = node[:database][:db_name]
    db_user = node[:database][:db_user]
    db_password = node[:database][:db_password]
    db_host = 'localhost'

    # Write out wp-config.php
    template "#{deploy_root}/wordpress/wp-config.php" do
        source "srv/www/APPNAME/RELEASETIME/wp-config.php.erb" # folder structure reflects production environment -- doesn't match up here. Sorry.
        
        variables(
            :database   => (db_name rescue nil),
            :user       => (db_user rescue nil),
            :password   => (db_password rescue nil),
            :host       => (db_host rescue nil),
            :keys       => (keys rescue nil)
        )
    end
end