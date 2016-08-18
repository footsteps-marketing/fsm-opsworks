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
  initial_root_password 'the_password'
  action [:create, :start]
end

[
    'php-xdebug',
    'npm'
].each do |installPackage|
    package "#{installPackage}" do
        package_name installPackage
    end
end

template "/etc/php/7.0/fpm/php.ini" do
    action :nothing
    subscribes :create, 'package[php-fpm]', :immediately
    source "php.ini.erb"

end