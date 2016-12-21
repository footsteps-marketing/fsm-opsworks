#
# Cookbook Name:: fsm-opsworks
# Recipe:: configure-cloudwatch-logs
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

directory "/opt/aws/cloudwatch" do
  recursive true
end

remote_file "/opt/aws/cloudwatch/awslogs-agent-setup.py" do
  source "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
  notifies :run, 'execute[install_cflogs_agent]', :immediately
  mode "0755"
end
 
execute "install_cflogs_agent" do
  action :nothing
  command "/opt/aws/cloudwatch/awslogs-agent-setup.py -n -r #{node[:cwlogs][:region]} -c /tmp/cwlogs.cfg"
  notifies :write, 'log[install_cflogs_agent]', :immediately
  notifies :run, 'execute[start_cflogs_agent]', :immediately
  not_if { system "pgrep -f aws-logs-agent-setup" }
end

execute "start_cflogs_agent" do
  action :nothing
  notifies :write, 'log[start_cflogs_agent]', :immediately
  command "systemctl enable awslogs; systemctl restart awslogs"
end

log "install_cflogs_agent" do
    action :nothing
    level :info
    message "********** execute[install_cflogs_agent] happened"
end

log "start_cflogs_agent" do
    action :nothing
    level :info
    message "********** execute[start_cflogs_agent] happened"
end