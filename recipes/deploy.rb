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

    deploy_root = "/srv/www/#{app['shortname']}"
    Chef::Log.info("***** Deploying #{app['shortname']} at #{command['sent_at']} ")
    current_revision = command['sent_at']

    # if app['app_source']['type'] == 'git'
    #     git "#{deploy_root}" do
    #         revision app['app_source']['revision'] 
    #         repository app['app_source']['url'] 
    #         action :sync
    #     end
    # end
end