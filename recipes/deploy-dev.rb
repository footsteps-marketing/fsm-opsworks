#
# Cookbook Name:: fsm-opsworks
# Recipe:: deploy
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

require 'uri'
require 'net/http'
require 'net/https'

search("aws_opsworks_app").each do |app|

    # Set the deploy user
    # @todo -- do this programmatically?
    deploy_user = 'www-data'
    deploy_group = 'www-data'

    # Get a nice numeric string for the current version and set paths accordingly
    deploy_root = "/srv/www/#{app['shortname']}/current"
    Chef::Log.info("**************** Deploying #{app['shortname']} to #{deploy_root}")

    

    # Write out the wordpress multisite snippet
    template "/etc/nginx/snippets/wordpress.conf" do
        # action :nothing
        # subscribes :create, 'package[nginx]', :immediately
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
        # action :nothing
        # subscribes :create, 'package[nginx]', :immediately
        source "site.conf.erb"
        mode 0644
        owner "root"
        group "root"

        variables(
            :logbase => '/vagrant/log/nginx',
            :app => (app rescue nil),
            :ssl => node[:letsencrypt][:get_certificates]
        )
    end

    # Clean up old linked confs...
    link "/etc/nginx/sites-enabled/default" do
        action :delete
        # subscribes :delete, 'package[nginx]', :immediately
        only_if "test -L '/etc/nginx/sites-enabled/default'"
    end

    # Link the new confs...
    link "/etc/nginx/sites-enabled/#{app['shortname']}.conf" do
        to "/etc/nginx/sites-available/#{app['shortname']}.conf"
        # action :nothing
        # subscribes :create, 'package[nginx]', :immediately
        if node[:letsencrypt][:get_certificates] == false
            notifies :restart, "service[nginx]", :delayed
        end
    end

    #
    # Now write out the domain confs...
    # 
    domain = 'fsm-wordpress.dev'
    Chef::Log.info("***** Mapping Domain: #{domain}")
    template "/etc/nginx/sites-available/#{domain}.conf" do
        # action :nothing
        # subscribes :create, 'package[nginx]', :immediately
        source "site.conf.erb"
        mode 0644
        owner "root"
        group "root"

        variables(
            :logbase => '/vagrant/log/nginx',
            :app => (app rescue nil),
            :url => (domain rescue nil),
            :ssl => node[:letsencrypt][:get_certificates]
        )
    end

    link "/etc/nginx/sites-enabled/#{domain}.conf" do
        # action :nothing
        # subscribes :create, "template[/etc/nginx/sites-available/#{domain}.conf]", :immediately
        to "/etc/nginx/sites-available/#{domain}.conf"
        if node[:letsencrypt][:get_certificates] == false
            notifies :restart, "service[nginx]", :delayed
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
    db_name = 'fsm_wordpress'
    db_user = 'root'
    db_password = 'the_password'
    db_host = 'localhost'

    # Write out wp-config.php
    template "#{deploy_root}/wp-config.php" do
        # action :nothing
        # subscribes :create, 'package[nginx]', :immediately
        source "wp-config.php.erb"
        
        variables(
            :database   => (db_name rescue nil),
            :user       => (db_user rescue nil),
            :password   => (db_password rescue nil),
            :host       => (db_host rescue nil),
            :keys       => (keys rescue nil)
        )
    end




    # Restart nginx for good measure
    service "nginx" do
        action :nothing
    end
end