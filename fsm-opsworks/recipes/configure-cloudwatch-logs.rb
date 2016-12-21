#
# Cookbook Name:: fsm-opsworks
# Recipe:: configure-cloudwatch-logs
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

apps = search("aws_opsworks_app")
stack = search("aws_opsworks_stack").first
instance = search("aws_opsworks_instance").first

template "/tmp/cwlogs.cfg" do
  source "tmp/cwlogs.cfg.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :logbase => '/var/log/nginx',
    :apps => (apps rescue nil),
    :stack => (stack rescue nil)
    :instance => (instance rescue nil)
  )
end
