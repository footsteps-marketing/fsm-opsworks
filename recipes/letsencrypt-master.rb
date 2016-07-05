#
# Cookbook Name:: fsm-opsworks
# Recipe:: letsencrypt-master
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

# 
# Get the domains to map out of the database
# 

search("aws_opsworks_app").first do |app|
    
    # Bail out if not deploying this app
    if app['deploy'] === false
        next
    end

    # Set the deploy user
    # @todo -- do this programmatically?
    deploy_user = 'www-data'
    deploy_group = 'www-data'

    # Get a nice numeric string for the current version and set paths accordingly
    app_root = "/srv/www/#{app['shortname']}/current"

    domains = Array.new
        
    ruby_block "check_curl_command_output" do
        block do
            #tricky way to load this Chef::Mixin::ShellOut utilities
            Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
            command = "php #{app_root}/current/get-mapped-domains.php"
            command_out = shell_out(command)
            domains = command_out.stdout.split("\n")
        end
        action :create
    end

    domains.each do |domain|
        log 'domain_mapping_list' do
            message "Mapping: #{domain}"
            level :info
        end
    end

    domains.unshift("#{node[:wordpress][:multisite][:domain_current_site]}")



    domains.each do |domain|

        script "letsencrypt_doer" do
            interpreter "bash"
            user "root"
            code <<-EOH
            letsencrypt --no-self-upgrade --webroot --expand --non-interactive --keep-until-expiring --agree-tos --email "#{node[:letsencrypt][:admin_email]}" --webroot-path "#{app_root}/current" -d "#{domain}"
            EOH
        end

        template "/etc/nginx/sites-available/#{domain}.conf" do
            source "site.conf.erb"
            mode 0644
            owner "root"
            group "root"

            variables(
                :app => (app rescue nil),
                :url => (domain rescue nil),
                :ssl => Dir.exist?("/etc/letsencrypt/live/#{domain}")
            )
        end

        link "/etc/nginx/sites-enabled/#{domain}.conf" do
            to "/etc/nginx/sites-available/#{domain}.conf"
        end

    end

end