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
    deploy_user = 'www-data'
    deploy_group = 'www-data'

    current_revision = command['sent_at'].delete("^0-9")
    deploy_root = "/srv/www/#{app['shortname']}/#{current_revision}"
    Chef::Log.info("**************** Deploying #{app['shortname']} to #{deploy_root}")

    directory "#{deploy_root}" do
        owner deploy_user
        group deploy_group
        mode '0775'
        recursive true
        action :create
    end

    if app['app_source']['type'] == 'git'
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
    
    # template "#{deploy_root}/wp-config.php" do
    #     source "wp-config.php.erb"
    #     mode 0660
    #     owner deploy_owner
    #     group deploy_group
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