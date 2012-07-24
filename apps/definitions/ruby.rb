#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: apps
# Definition:: ruby
#
# Copyright 2011, Boundary
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# installl standard dependencies
#

define :install_standard_ruby_dependencies, :name => nil, :deploy_config => nil do

  include_recipe "git"

end

#
# git deploy specifically for ruby apps
#

define :git_deploy_ruby, :name => nil, :deploy_config => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end

  git "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}" do
    repository  deploy_config["config"]["git"]["repository"]
    reference   deploy_config["config"]["git"]["reference"]
    action      :sync
    ssh_wrapper "#{deploy_config["install"]["path"]}/etc/git_ssh.sh"
    notifies(:restart, resources(:service => deploy_config["id"]))
  end

end

define :tarball_deploy_ruby, :name => nil, :deploy_config => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end

  filename = "#{deploy_config["id"]}_#{deploy_config["version"]}.tar.gz"

  remote_file "/tmp/#{filename}" do
    source "#{deploy_config["install"]["repo_url"]}/#{deploy_config["id"]}/#{filename}"
    mode 0644
    not_if "/usr/bin/test -d #{deploy_config["install"]["path"]}/#{deploy_config["id"]}_#{deploy_config["version"]}"
  end

  bash "install #{deploy_config["id"]}" do
    user "root"
    cwd "/tmp"
    code <<-EOH
    (tar zxf /tmp/#{filename})
    (mv #{deploy_config["id"]} #{deploy_config["install"]["path"]}/#{deploy_config["id"]}_#{deploy_config["version"]})
    (rm -f /tmp/#{filename})
    (chown -R #{deploy_config["system"]["user"]}:#{deploy_config["system"]["group"]} #{deploy_config["install"]["path"]})
    EOH
    not_if "/usr/bin/test -d #{deploy_config["install"]["path"]}/#{deploy_config["id"]}_#{deploy_config["version"]}"
  end

  link "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}" do
    to "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}_#{deploy_config["version"]}"
    owner deploy_config["system"]["user"]
    group deploy_config["system"]["group"]
    notifies :restart, resources(:service => "#{deploy_config["id"]}")
  end

end

define :setup_main_config_yml, :name => nil, :deploy_config => nil, :app_options => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end

  template "#{deploy_config["install"]["path"]}/etc/#{deploy_config["id"]}.yml" do
    source  "config.yml.erb"
    owner   deploy_config["system"]["user"]
    group   deploy_config["system"]["group"]
    mode    0644
    variables :deploy_config => deploy_config, :app_options => params[:app_options]
    notifies :restart, resources(:service => "#{deploy_config["id"]}")
  end

end

#
# bundle_install if needed
#

define :bundle_install, :name => nil, :deploy_config => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end

  if deploy_config["config"]["bundler"]
    execute "bundle_install" do
      user deploy_config["system"]["user"]
      group deploy_config["system"]["group"]
      cwd "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}"
      command "bundle install --local --deployment --without=test:development"
    end
  end

end

#
# unicorn setup if needed
#

define :unicorn_config, :name => nil, :deploy_config => nil, :app_options => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end

  if deploy_config["config"]["unicorn"]
    template "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}/unicorn.rb" do
      source "unicorn.rb.erb"
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode 0644
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :restart, resources(:service => "#{deploy_config["id"]}")
    end

    directory "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}/pids" do
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode 0755
    end
  end

end