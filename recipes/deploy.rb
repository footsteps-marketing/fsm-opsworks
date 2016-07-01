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
        key_path = "/tmp/keys/#{app['shortname']}_rsa"
        
        directory "/tmp/keys" do
            owner 'root'
            group 'root'
            mode '0700'
            recursive true
            action :create
        end

        if app['app_source']['ssh_key'] != 'null'
            file "#{key_path}" do
                owner "root"
                group "root"
                mode "0600"
                content "#{app['app_source']['ssh_key']}"
            end
            file "#{key_path}.sh" do
                owner "root"
                group "root"
                mode "0755"
                content "#!/bin/sh\nwhoami\nexec /usr/bin/ssh -i #{key_path} \"$@\""
            end
        end

        git "#{deploy_root}" do
            revision app['app_source']['revision']
            repository app['app_source']['url']
            user deploy_user
            group deploy_group
            if app['app_source']['ssh_key'] != 'null'
                ssh_wrapper "#{key_path}.sh"
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