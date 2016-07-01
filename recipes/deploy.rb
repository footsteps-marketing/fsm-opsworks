#
# Cookbook Name:: fsm-opsworks
# Recipe:: deploy
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

command = search('aws_opsworks_command').first

search("aws_opsworks_app").each do |app|
    if app['deploy'] === false
        next
    end

    current_revision = command['sent_at'].delete("^0-9")
    deploy_root = "/srv/www/#{app['shortname']}/#{current_revision}"
    Chef::Log.info("**************** Deploying #{app['shortname']} to #{deploy_root}")

    if app['app_source']['type'] == 'git'
        key_path = "/var/keys/#{app['shortname']}_rsa"

        if app['app_source']['ssh_key'] != 'null'
            file "#{key_path}" do
                owner "root"
                group "root"
                mode "0600"
                content "#{app['app_source']['ssh_key']}"
            end
        end

        git "#{deploy_root}" do
            revision app['app_source']['revision'] 
            repository app['app_source']['url'] 
            if app['app_source']['ssh_key'] != 'null'
                ssh_wrapper "ssh -i #{key_path}"
            end
            action :sync
        end
    end
    
    # template "#{deploy_root}/wp-config.php" do
    #     source "wp-config.php.erb"
    #     mode 0660
    #     group 'www-data'
    #     owner "www-data"
    #     
    #     variables(
    #         :database   => (deploy[:database][:database] rescue nil),
    #         :user       => (deploy[:database][:username] rescue nil),
    #         :password   => (deploy[:database][:password] rescue nil),
    #         :host       => (deploy[:database][:host] rescue nil),
    #         :keys       => (keys rescue nil)
    #     )
    # end
end