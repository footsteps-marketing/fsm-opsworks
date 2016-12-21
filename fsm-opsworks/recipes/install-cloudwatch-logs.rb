#
# Cookbook Name:: fsm-opsworks
# Recipe:: install-cloudwatch-logs
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

directory "/opt/aws/cloudwatch" do
  recursive true
end

remote_file "download_cflogs_agent" do
  source "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
  path "/opt/aws/cloudwatch/awslogs-agent-setup.py"
  mode "0755"
end
 
execute "install_cflogs_agent" do
  command "/opt/aws/cloudwatch/awslogs-agent-setup.py -n -r #{node[:cwlogs][:region]} -c /tmp/cwlogs.cfg"
  action :nothing
  subscribes :run, 'remote_file[download_cflogs_agent]', :immediately
  notify :enable, 'service[awslogs]', :immediately
  notify :restart, 'service[awslogs]', :immediately
end

service "awslogs" do 
    action :nothing
end