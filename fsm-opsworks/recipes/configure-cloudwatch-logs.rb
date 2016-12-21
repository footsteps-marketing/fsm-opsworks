#
# Cookbook Name:: fsm-opsworks
# Recipe:: configure-cloudwatch-logs
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

template "/tmp/cwlogs.cfg" do
  source "tmp/cwlogs.cfg.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :logbase => '/var/log/nginx',
    :apps => (search("aws_opsworks_app") rescue nil),
    :stack => (search("aws_opsworks_stack").first rescue nil),
    :instance => (search("aws_opsworks_instance", "self:true").first rescue nil),
  )
end
