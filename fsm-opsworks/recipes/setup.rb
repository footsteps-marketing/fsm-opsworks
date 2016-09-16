#
# Cookbook Name:: fsm-opsworks
# Recipe:: setup
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

# Install some necessary packages 
[
    'nginx',
    'php-fpm',
    'php-mysql',
    'php-mcrypt',
    'php-curl',
    'php-apcu',
    'php7.0-xml',
    'php-mbstring',
    'php-memcache',
    'pngquant',
    'jpegoptim',
    'imagemagick',
].each do |installPackage|
    Chef::Log.info("**************** Installing Package #{installPackage}")
    package "#{installPackage}" do
        package_name installPackage
    end
end
