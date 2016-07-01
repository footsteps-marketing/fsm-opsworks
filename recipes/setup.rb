#
# Cookbook Name:: fsm-opsworks
# Recipe:: setup
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

[
    'nginx',
    'php-fpm',
    'php-mysql',
    'php-mcrypt',
    'php7.0-xml',
    'letsencrypt'
].each do |installPackage|
    package "Install #{installPackage}" do
        package_name installPackage
    end
end

# Handle a bug with kswapd0 eating lots of CPU
# See http://askubuntu.com/a/764134
cron "fix_kswapd0" do
    user 'root'
    command "echo 1 > /proc/sys/vm/drop_cache"
end