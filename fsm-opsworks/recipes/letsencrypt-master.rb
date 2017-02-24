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

    # Get a nice numeric string for the current version and set paths accordingly
    app_root = "/srv/www/#{app['shortname']}/current"

    Domains.get app_root node[:wordpress][:multisite][:domain_current_site] do |domains|
        domains.each do |domain|            
            script "letsencrypt_doer" do
                interpreter "bash"
                user "root"
                code <<-EOH
                letsencrypt --no-self-upgrade --webroot --expand --non-interactive --keep-until-expiring --agree-tos --email "#{node[:letsencrypt][:admin_email]}" --webroot-path "#{app_root}/current" -d "#{domain}"
                EOH
            end
        end
    end

end