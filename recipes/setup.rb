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

# Handle a bug with kswapd0 eating lots of CPU
# See http://askubuntu.com/a/764134
cron "fix_kswapd0" do
    user 'root'
    command "echo 1 > /proc/sys/vm/drop_cache"
end

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