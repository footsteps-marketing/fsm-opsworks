#
# Cookbook Name:: fsm-opsworks
# Recipe:: letsencrypt-slave
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

search("aws_opsworks_app").first do |app|
    
    # Bail out if not deploying this app
    if app['deploy'] === false
        next
    end

    Domains.get app_root node[:wordpress][:multisite][:domain_current_site] do |domains|
        domains.each do |domain|
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
end