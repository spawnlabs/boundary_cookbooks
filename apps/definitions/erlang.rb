#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: apps
# Definition:: erlang
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
# installl standard erlang dependencies
#

define :install_standard_erlang_dependencies, :name => nil, :deploy_config => nil do

  include_recipe "erlang::erl_call"
  include_recipe "erlang::epmd"
  
end

#
# install erlang release
#

define :install_erlang_release, :name => nil, :deploy_config => nil do
  
  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end
  
  filename = "#{deploy_config["id"]}_#{deploy_config["version"]}.tar.gz"
  
  remote_file "/tmp/#{filename}" do
    source "#{deploy_config["install"]["repo_url"]}/#{deploy_config["id"]}/releases/#{filename}"
    mode 0644
    not_if "/usr/bin/test -d #{deploy_config["install"]["path"]}"
  end
  
  bash "install #{deploy_config["id"]}" do
    user "root"
    cwd "/opt"
    code <<-EOH
    (tar zxf /tmp/#{filename} -C /opt)
    (rm -f /tmp/#{filename})
    EOH
    not_if "/usr/bin/test -d #{deploy_config["install"]["path"]}"
  end
  
end

#
# erlang main config
#

define :erlang_config, :name => nil, :deploy_config => nil, :app_options => nil do
  
  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end
  
  template "#{deploy_config["install"]["path"]}/releases/#{deploy_config["version"]}/sys.config" do
    source "#{deploy_config["type"]}/#{deploy_config["id"]}/config.erb"
    owner deploy_config["system"]["user"]
    group deploy_config["system"]["group"]
    mode 0644
    variables :deploy_config => deploy_config, :app_options => params[:app_options]
    only_if "/usr/bin/test -d #{deploy_config["install"]["path"]}/releases/#{deploy_config["version"]}"
    notifies :restart, resources(:service => "#{deploy_config["id"]}")
  end
  
end

#
# erlang vm.args
#

define :erlang_vm_args, :name => nil, :deploy_config => nil, :app_options => nil do
  
  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end
  
  template "#{deploy_config["install"]["path"]}/releases/#{deploy_config["version"]}/vm.args" do
    source "#{deploy_config["type"]}/#{deploy_config["id"]}/vm.args.erb"
    owner deploy_config["system"]["user"]
    group deploy_config["system"]["group"]
    mode 0644
    variables :deploy_config => deploy_config, :app_options => params[:app_options]
    notifies :restart, resources(:service => "#{deploy_config["id"]}")
  end
  
end

#
# erlang hot upgrade
#

define :erlang_hot_upgrade, :name => nil, :deploy_config => nil, :upgrade_code => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end
  
  remote_file "#{deploy_config["install"]["path"]}/releases/#{filename}" do
    source "#{deploy_config["install"]["repo_url"]}/#{deploy_config["id"]}/upgrades/#{filename}"
    owner deploy_config["system"]["user"]
    group deploy_config["system"]["group"]
    not_if "/usr/bin/test -d #{deploy_config["install"]["path"]}/releases/#{deploy_config["version"]}"
  end
  
  if params[:upgrade_code]
    upgrade_code = params[:upgrade_code]
  else
    upgrade_code = <<-EOH
    {ok, _} = release_handler:unpack_release("#{deploy_config["id"]}_#{deploy_config["version"]}"),
    {ok, _, _} = release_handler:install_release("#{deploy_config["version"]}"),
    ok = release_handler:make_permanent("#{deploy_config["version"]}").
    EOH
  end
  
  erl_call "upgrade #{deploy_config["id"]}" do
    node_name "#{deploy_config["id"]}@#{node[:fqdn]}"
    name_type "name"
    cookie deploy_config["erlang"]["cookie"]
    code upgrade_code
    not_if "/usr/bin/test -d #{deploy_config["install"]["path"]}/releases/#{deploy_config["version"]}"
  end

end