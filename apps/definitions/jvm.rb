#
# installl standard jvm dependencies
#

define :install_standard_jvm_dependencies, :name => nil, :deploy_config => nil do
  
  include_recipe "java"
  
end

#
# setup basic directories needed for deploy
#

define :setup_jvm_application_directories, :name => nil, :deploy_config => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end
  
  %w[ lib etc bin ].each do |dir|
    directory "#{deploy_config["install"]["path"]}/#{dir}" do
      owner deploy_config["system"]["user"]
      group deploy_config["system"]["group"]
      recursive true
    end
  end
  
end

#
# install fat jar
#

define :install_jvm_release, :name => nil, :deploy_config => nil do
  
  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end
  
  local_filename = "#{deploy_config["id"]}.jar"
  remote_filename = "#{deploy_config["id"]}_#{deploy_config["version"]}.jar"

  remote_file "#{deploy_config["install"]["path"]}/lib/#{local_filename}" do
    source "#{deploy_config["install"]["repo_url"]}/#{deploy_config["id"]}/#{remote_filename}"
    backup false
    mode 0644
    checksum deploy_config["checksum"]
    notifies :restart, resources(:service => "#{deploy_config["id"]}")
  end
  
end

#
# setup default log4j config
#

define :setup_log4j_config, :name => nil, :deploy_config => nil, :app_options => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end
  
  template "#{deploy_config["install"]["path"]}/etc/log4j.properties" do
    source "jvm/log4j.properties.erb"
    owner deploy_config["system"]["user"]
    group deploy_config["system"]["group"]
    mode 0644
    variables :deploy_config => deploy_config, :app_options => params[:app_options]
    notifies :restart, resources(:service => "#{deploy_config["id"]}")
  end
  
end