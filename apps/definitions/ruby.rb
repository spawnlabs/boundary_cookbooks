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

define :setup_main_config_yml, :name => nil, :deploy_config => nil, :app_options => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end
  
  template "#{deploy_config["install"]["path"]}/etc/#{deploy_config["id"]}.yml" do
    source  "ruby/#{deploy_config["id"]}/config.yml.erb"
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
      cwd "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}"
      command "bundle install --deployment --without=test:development"
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
      source "ruby/#{deploy_config["id"]}/unicorn.rb.erb"
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