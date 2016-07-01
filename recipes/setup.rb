#
# Cookbook Name:: fsm-opsworks
# Recipe:: setup
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

package "Install nginx" do
    package_name "nginx"
end

package "Install php" do
    package_name "php-fpm"
end

package "Install php-mysql" do
    package_name "php-mysql"
end

package "Install php-mcrypt" do
    package_name "php-mcrypt"
end

package "Install letsencrypt" do
    package_name "letsencrypt"
end

# Handle a bug with kswapd0 eating lots of CPU
# See http://askubuntu.com/a/764134
cron "fix_kswapd0" do
    user 'root'
    command "echo 1 > /proc/sys/vm/drop_cache"
end