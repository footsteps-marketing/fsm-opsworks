#
# Cookbook Name:: fsm-opsworks
# Recipe:: setup
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

#
# Install some necessary packages
# 
[
    'nginx',
    'php-fpm',
    'php-mysql',
    'php-mcrypt',
    'php-curl',
    'php7.0-xml',
    'letsencrypt',
    'pngquant',
    'jpegoptim',
    'imagemagick'
].each do |installPackage|
    package "Install #{installPackage}" do
        package_name installPackage
    end
end



#
# Handle a bug with kswapd0 eating lots of CPU
# See http://askubuntu.com/a/764134
# 
reboot 'now' do
    action :nothing
    reason 'Need to reboot for a fix'
end

file '/etc/udev/rules.d/40-vm-hotadd.rules' do
    owner 'root'
    group 'root'
    action :touch
    notifies :reboot_now, 'reboot[now]', :immediately
end


# 
# Install some image processing libraries
# 
script "install_mozjpeg" do
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