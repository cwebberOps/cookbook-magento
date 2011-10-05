if node.has_key?("ec2")
  server_fqdn = node.ec2.public_hostname
else
  server_fqdn = node.fqdn
end

if "webmaster@localhost" == node[:magento][:admin][:email]
  admin_email = "webmaster@#{server_fqdn}"
else
  admin_email = node[:magento][:admin][:email]
end

# Required extensions
%w{php5-cli php5-common php5-curl php5-gd php5-mcrypt php5-mysql php-pear}.each do |package|
  package "#{package}" do
    action :upgrade
  end
end

bash "Tweak php.ini file" do
  cwd "/etc/php5/cli"
  code <<-EOH
  sed -i 's/memory_limit = .*/memory_limit = 128M/' php.ini
  sed -i 's/;realpath_cache_size = .*/realpath_cache_size = 32K/' php.ini
  sed -i 's/;realpath_cache_ttl = .*/realpath_cache_ttl = 7200/' php.ini
  EOH
end

unless File.exists?("#{node[:magento][:dir]}/installed.flag")
  user "#{node[:magento][:user]}" do
    comment "magento guy"
    home "#{node[:magento][:dir]}"
    system true
  end
  directory "#{node[:magento][:dir]}/app/etc" do
    owner "#{node[:magento][:user]}"
    group "www-data"
    mode "0755"
    action :create
    recursive true
  end
end

template "#{node[:magento][:dir]}/app/etc/local.xml" do
  source "local.xml.erb"
  mode "0600"
  owner "#{node[:magento][:user]}"
  group "www-data"
  variables(:database => node[:magento][:db])
end
