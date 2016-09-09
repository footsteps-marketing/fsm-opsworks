#
# Cookbook Name:: fsm-opsworks
# Recipe:: configure
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

template "/etc/nginx/snippets/wordfence.conf" do
    source "wordfence.conf.erb"
    mode 0644
    owner "root"
    group "root"
end