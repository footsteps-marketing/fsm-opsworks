#
# Cookbook Name:: fsm-opsworks
# Recipe:: install-cloudwatch-logs
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

directory "/opt/aws/cloudwatch" do
  recursive true
end

remote_file "/tmp/awslogs-agent-setup.py" do
  source "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
  mode "0755"
end
 
execute "install_cflogs_agent" do
  command "/tmp/awslogs-agent-setup.py -n -r #{node[:cwlogs][:region]} -c /tmp/cwlogs.cfg"
  retries 3
  retry_delay 3
  notifies :enable, 'service[awslogs]', :immediately
  notifies :restart, 'service[awslogs]', :immediately
end

service "awslogs" do 
    action :nothing
end