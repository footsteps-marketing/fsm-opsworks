#
# Cookbook Name:: fsm-opsworks
# Recipe:: setup-production
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

# 
# Install some image processing libraries
# 
bash "handle_kswapd0_bug" do
    user "root"
    code "touch /etc/udev/rules.d/40-vm-hotadd.rules"
    notifies :request_reboot, 'reboot[required]', :delayed
end

reboot 'required' do
    action :nothing
end