#
# Cookbook Name:: fsm-opsworks
# Recipe:: setup
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

#
# Install some necessary packages
# 
mysql_service 'default' do
  port '3306'
  version '5.7'
  initial_root_password node[:database][:db_password]
  action [:create, :start]
end

[
    'php-xdebug',
    'npm',
    'subversion'
].each do |installPackage|
    package "#{installPackage}" do
        package_name installPackage
    end
end

template "/etc/php/7.0/fpm/php.ini" do
    action :nothing
    subscribes :create, 'package[php-fpm]', :delayed
    notifies :restart, 'service[php7.0-fpm]', :delayed
    source "etc/php/7.0/fpm/php.ini.erb"
end

template "/etc/php/7.0/cli/php.ini" do
    action :nothing
    subscribes :create, 'package[php-fpm]', :delayed
    source "etc/php/7.0/cli/php.ini.erb"
end

service "php7.0-fpm" do
    action :nothing
end

service "nginx" do
    action :nothing
end

script "install_wp_cli" do
    interpreter "bash"
    cwd "/tmp"
    user "root"
    code <<-EOH
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
    EOH
end