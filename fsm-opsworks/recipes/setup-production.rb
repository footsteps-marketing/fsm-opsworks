#
# Cookbook Name:: fsm-opsworks
# Recipe:: setup-production
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

# 
# Install some image processing libraries
# 
[
    'letsencrypt',
    'build-essential',
    'git',
    'autoconf',
    'pkg-config',
    'nasm',
    'libtool'
].each do |installPackage|
    package "#{installPackage}" do
        package_name installPackage
    end
end

script "install_mozjpeg" do
    action :nothing
    subscribes :run, 'package[build-essential]', :delayed
    interpreter "bash"
    cwd "/tmp"
    user "root"
    code <<-EOH
        if [ ! -f /opt/mozjpeg/bin/cjpeg ]; then
            sudo apt-get install -y build-essential autoconf pkg-config nasm libtool
            git clone https://github.com/mozilla/mozjpeg.git
            cd mozjpeg
            autoreconf -fiv
            ./configure --with-jpeg8
            make
            sudo make install
        fi
    EOH
end

script "install_jpegarchive" do
    action :nothing
    subscribes :run, 'package[build-essential]', :delayed
    interpreter "bash"
    cwd "/tmp"
    user "root"
    code <<-EOH
        if [ ! -f /usr/local/bin/jpeg-recompress ]; then
            git clone https://github.com/danielgtaylor/jpeg-archive.git
            cd jpeg-archive
            make
            sudo make install
        fi
    EOH
end