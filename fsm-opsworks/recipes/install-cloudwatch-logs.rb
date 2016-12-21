#
# Cookbook Name:: fsm-opsworks
# Recipe:: configure-cloudwatch-logs
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

directory "/opt/aws/cloudwatch" do
  recursive true
  notifies :create, 'remote_file[/opt/aws/cloudwatch/awslogs-agent-setup.py]', :immediately
end

remote_file "/opt/aws/cloudwatch/awslogs-agent-setup.py" do
  action :nothing
  source "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
  notifies :run, 'execute[Install CloudWatch Logs agent]', :immediately
  mode "0755"
end
 
execute "Install CloudWatch Logs agent" do
  action :nothing
  command "/opt/aws/cloudwatch/awslogs-agent-setup.py -n -r #{node[:cwlogs][:region]} -c /tmp/cwlogs.cfg"
  notifies :run, 'execute[Start CloudWatch Logs agent]', :immediately
  not_if { system "pgrep -f aws-logs-agent-setup" }
end

execute "Start CloudWatch Logs agent" do
  action :nothing
  command "systemctl enable awslogs; systemctl restart awslogs"
end