#
# Cookbook Name:: fsm-opsworks
# Recipe:: distribute-certs
#
# Copyright (c) 2017 FootSteps Marketing, All Rights Reserved.

command = search(:aws_opsworks_command).first
  
http_request 'ssl_manager' do
  url "http://acme.footstepsmarketing.com:8080/command/#{command['command_id']}"
end