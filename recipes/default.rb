=begin

License: WTFPL

(ノಠ益ಠ)ノ彡┻━┻

Deploy ruby they said. It’ll be fun they said.
Fuck ruby. Fuck rvm. Fuck chef. Fuck PuercoPop
=end

include_recipe "apt"
include_recipe "git"
include_recipe "rbenv"
include_recipe "nginx"
include_recipe "postfix"
include_recipe "supervisor"
include_recipe "build-essential"
include_recipe "rbenv::ruby_build"
include_recipe "rbenv::rbenv_vars"
include_recipe "postgresql::server"
include_recipe "postgresql::contrib"

apt_repository "redis-ppa" do
  uri "http://ppa.launchpad.net/rwky/redis/ubuntu"
  distribution "precise "#node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "5862E31D"
end

packages = [
  "redis-server", "libxml2-dev", "libxslt1-dev",
]

packages.each do |pkg|
  package pkg
end

user node['discourse']['user'] do
  supports :manage_home => true
  comment "Discourse User"
  home "/home/#{node['discourse']['user']}"
  shell "/bin/bash"
  action :create
end

group node['discourse']['group'] do
  members [node['discourse']['user']]
end

group node['rbenv']['group'] do
  action :modify
  members [node['discourse']['user']]
  append true
end

rbenv_ruby node['discourse']['ruby_version'] do
  action :install
end

rbenv_gem 'bundler' do
  ruby_version node['discourse']['ruby_version']
end

directory node['discourse']['install_dir'] do
  owner node['discourse']['user']
  group node['discourse']['group']
  recursive true
  mode  0755
end

git node['discourse']['install_dir'] do
  repository "https://github.com/discourse/discourse.git"
  revision "#{node['discourse']['release']}"
  user node['discourse']['user']
  group node['discourse']['group']
  action :checkout
end

# This resources belongs to "phlipper/chef-postgresql" becuase, the "database"
# cookbook from opscode is a pain in the  ass.
#
# note: superuser, because it's necessary create extensions
pg_user node['discourse']['dbuser'] do
  privileges :superuser => true, :createdb => false, :login => true
  password node['discourse']['dbpass']
end

pg_database node['discourse']['dbname'] do
  owner node['discourse']['dbuser']
  encoding "utf8"
  template "template0"
  locale "en_US.UTF8"
end

pg_database node['discourse']['dbname_test'] do
  owner node['discourse']['dbuser']
  encoding "utf8"
  template "template0"
  locale "en_US.UTF8"
end

# This doesn't works becuase chef adds the peer method authentication for all
# the local connections. <o>
#
# pg_hba = [
#   {:type => 'local', :db => node['discourse']['dbname'], :user => node['discourse']['dbuser'], :addr => nil, :method => 'password'},
#   {:type => 'local', :db => node['discourse']['dbname_test'], :user => node['discourse']['dbuser'], :addr => nil, :method => 'password'},
# ]
#
# node['postgresql']['pg_hba'].concat(pg_hba)

template "#{node['discourse']['install_dir']}/config/database.yml" do
  user node['discourse']['user']
  source "database.yml.erb"
end

template "#{node['discourse']['install_dir']}/config/redis.yml" do
  user node['discourse']['user']
  source "redis.yml.erb"
end

template "#{node['nginx']['dir']}/sites-enabled/discourse.conf" do
  user node['nginx']['user']
  source "nginx.conf.erb"
  notifies :reload, "service[nginx]"
end

template "#{node['discourse']['install_dir']}/.ruby-version" do
  user node['discourse']['user']
  group node['discourse']['group']
  source "ruby-version.erb"
end

template "#{node['discourse']['install_dir']}/config/initializers/secret_token.rb" do
  user node['discourse']['user']
  group node['discourse']['group']
  source "secret_token.rb.erb"
end

cookbook_file "/home/#{node['discourse']['user']}/.gemrc" do
  user node['discourse']['user']
  group node['discourse']['group']
  source "gemrc"
end

rbenv_gem 'bluepill' do
  ruby_version node['discourse']['ruby_version']
end

execute "install_gems" do
  user 'root' #node['discourse']['user']
  cwd node['discourse']['install_dir']
  command "#{node['rbenv']['root']}/shims/bundle install --deployment --without test"
  environment({
    'RBENV_VERSION' => node['discourse']['ruby_version'],
  })
end

execute "db_migrate" do
  user node['discourse']['user']
  cwd node['discourse']['install_dir']
  command "#{node['rbenv']['root']}/shims/bundle exec rake db:migrate >/tmp/db:migrate.log 2>&1"
  environment({
    'RAILS_ENV' => 'production',
    'RBENV_VERSION' => node['discourse']['ruby_version'],
    'RUBY_GC_MALLOC_LIMIT' => '90000000',
    'SECRET_TOKEN' => node['discourse']['secret_token'],
  })
end

execute "assests_precompile" do
  user node['discourse']['user']
  cwd node['discourse']['install_dir']
  command "#{node['rbenv']['root']}/shims/bundle exec rake assets:precompile >/tmp/assets:precompile.log 2>&1"
  environment({
    'RAILS_ENV' => 'production',
    'RBENV_VERSION' => node['discourse']['ruby_version'],
    'RUBY_GC_MALLOC_LIMIT' => '90000000',
    'SECRET_TOKEN' => node['discourse']['secret_token'],
  })
end

execute "install_bluepill" do
  user 'root' #node['discourse']['user']
  cwd node['discourse']['install_dir']
  command "#{node['rbenv']['root']}/shims/bundle install --deployment --without test"
  environment({
    'RBENV_VERSION' => node['discourse']['ruby_version'],
  })
end

# directory "#{node['discourse']['install_dir']}/tmp" do
#   user node['discourse']['user']
#   group node['discourse']['group']
#   mode 00744
#   action :create
# end

# Run this shit
supervisor_service "thin" do
  command "#{node['rbenv']['root']}/shims/bundle exec thin start -e production --port #{node['discourse']['port']}"
  directory node['discourse']['install_dir']
  user node['discourse']['user']
  stdout_logfile "#{node['supervisor']['log_dir']}/thin.stdout.log"
  stderr_logfile "#{node['supervisor']['log_dir']}/thin.stderr.log"
  action :enable
  autostart true
  environment({
    'RAILS_ENV' => 'production',
    'RBENV_VERSION' => node['discourse']['ruby_version'],
    'RUBY_GC_MALLOC_LIMIT' => '90000000',
    'SECRET_TOKEN' => node['discourse']['secret_token'],
  })
end

supervisor_service "sidekiq_worker" do
  command "#{node['rbenv']['root']}/shims/bundle exec bundle exec sidekiq"
  directory node['discourse']['install_dir']
  user node['discourse']['user']
  stdout_logfile "#{node['supervisor']['log_dir']}/sidekiq_worker.stdout.log"
  stderr_logfile "#{node['supervisor']['log_dir']}/sidekiq_worker.stderr.log"
  action :enable
  autostart true
  environment({
    'RAILS_ENV' => 'production',
    'RBENV_VERSION' => node['discourse']['ruby_version'],
    'RUBY_GC_MALLOC_LIMIT' => '90000000',
    'SECRET_TOKEN' => node['discourse']['secret_token'],
  })
end

supervisor_service "clockwork" do
  command "#{node['rbenv']['root']}/shims/bundle exec clockwork config/clock.rb"
  directory node['discourse']['install_dir']
  user node['discourse']['user']
  stdout_logfile "#{node['supervisor']['log_dir']}/clockwork.stdout.log"
  stderr_logfile "#{node['supervisor']['log_dir']}/clockwork.stderr.log"
  action :enable
  autostart true
  environment({
    'RAILS_ENV' => 'production',
    'RBENV_VERSION' => node['discourse']['ruby_version'],
    'RUBY_GC_MALLOC_LIMIT' => '90000000',
    'SECRET_TOKEN' => node['discourse']['secret_token'],
  })
end
