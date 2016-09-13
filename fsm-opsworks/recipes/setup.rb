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
    'php7.0-xml',
    'php-mbstring',
    'pngquant',
    'jpegoptim',
    'imagemagick',
].each do |installPackage|
    package "#{installPackage}" do
        package_name installPackage
    end
end
