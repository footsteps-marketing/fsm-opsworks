#
# Cookbook Name:: fsm-opsworks
# Recipe:: deploy
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

command = search('aws_opsworks_command').first

search("aws_opsworks_app").each do |app|
    if deploy === false
        next
    end

    deploy_root = "/srv/www/#{app['shortname']}"
    Chef::Log.info("***** Deploying #{app['shortname']} at #{command['sent_at']} ")
    current_revision = command['sent_at']

    if app['app_source']['type'] == 'git'

    end
end