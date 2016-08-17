#
# Cookbook Name:: fsm-opsworks
# Recipe:: import-dev-database
#
# Copyright (c) 2016 FootSteps Marketing, All Rights Reserved.

db_name = 'fsm_wordpress'
db_user = 'root'
db_password = 'the_password'
db_host = 'localhost'
db_file = "/vagrant/env/db.sql"

bash 'import_database' do
    # action :nothing
    # subscribes :run, 'mysql_service[default]', :immediately
    code <<-EOH
        echo "Emptying local database..."
        mysql --socket=/var/run/mysql-default/mysqld.sock -h "localhost" -u "root" -p"the_password" << EOF
        DROP DATABASE IF EXISTS #{db_name};
        CREATE DATABASE #{db_name};
        GRANT ALL PRIVILEGES ON #{db_name}.* TO "#{db_user}"@"localhost"
        IDENTIFIED BY "#{db_password}";
        FLUSH PRIVILEGES;
EOF

        echo "Importing db.sql to local database (may take a minute)..."
        cat "#{db_file}" | mysql --socket=/var/run/mysql-default/mysqld.sock -h "localhost" -u "root" -p"the_password" "#{db_name}" && echo "Done!"

        mv "#{db_file}" "#{db_file}.imported"
    EOH
    only_if { ::File.exists?(db_file) }
end
