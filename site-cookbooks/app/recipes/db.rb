#
# Cookbook Name:: app
# Recipe:: db
#
# Credits: David Stanley (https://github.com/davidstanley01/vagrant-chef/)
# Copyright 2015, joschi127
#

# Fix /sbin/insserv: No such file or directory
bash "fix-sbin-insserv" do
  code "ln -sf /usr/lib/insserv/insserv /sbin/insserv"
end

# Create directory /var/run/mysqld
bash "create-directory-var-run-mysqld" do
  code "mkdir -p /var/run/mysqld && chmod a+rwX /var/run/mysqld"
end

# Install MySQL server & MySQL client
mysql_service 'default' do
    port '3306'
    initial_root_password node['mysql']['server_root_password']
    mysqld_options node['mysql']['mysqld_options']
    socket '/var/run/mysqld/mysqld.sock'
    service_manager "sysvinit"
    action [:create, :start]
end

# Install PostgreSQL
#include_recipe "postgresql::server"

# Create database if it doesn't exist
ruby_block "create_#{node['app']['name']}_db" do
    block do
        %x[mysql -uroot -p#{node['mysql']['server_root_password']} -e "CREATE DATABASE #{node['app']['db_name']};"]
    end 
    not_if "mysql -uroot -p#{node['mysql']['server_root_password']} -e \"SHOW DATABASES LIKE '#{node['app']['db_name']}'\" | grep #{node['app']['db_name']}";
    action :create
end

# Load default database if database dump file existing and database is empty
if File.exist?("#{node['app']['db_dump']}")
    ruby_block "seed #{node['app']['name']} database" do
        block do
            %x[mysql -u root -p#{node['mysql']['server_root_password']} #{node['app']['db_name']} < #{node['app']['db_dump']}]
        end
        not_if "mysql -u root -p#{node['mysql']['server_root_password']} -e \"SHOW TABLES FROM #{node['app']['db_name']}\" | \
            grep 1"
        action :create
    end
end
