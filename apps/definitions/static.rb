#
# installl standard dependencies
#

define :install_standard_static_dependencies, :name => nil, :deploy_config => nil do
  
  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end

  include_recipe "git"
    
  if deploy_config["config"]["webserver"] == "nginx"
    include_recipe "nginx"
  elsif deploy_config["config"]["webserver"] == "apache"
    include_recipe "apache2"
  end
  
end

#
# git deploy specifically for static apps
#

define :git_deploy_static, :name => nil, :deploy_config => nil do
  
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
  end
  
end


#
# web server config
#

define :web_server_config, :name => nil, :deploy_config => nil, :app_options => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end
  
  if deploy_config["config"]["webserver"] == "nginx"
        
    #
    # nginx config
    #
    
    template "#{node[:nginx][:dir]}/sites-available/#{deploy_config["id"]}.conf" do
      source "static/#{deploy_config["id"]}.conf.erb"
      owner "root"
      group "root"
      mode 0644
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :reload, resources(:service => "nginx")
    end
    
    nginx_site "#{deploy_config["id"]}.conf"
  
  elsif deploy_config["config"]["webserver"] == "apache"
        
    #
    # apache config
    #
    
    template "#{node[:apache][:dir]}/sites-available/#{deploy_config["id"]}.conf" do
      source "static/#{deploy_config["id"]}.conf.erb"
      owner "root"
      group "root"
      mode 0644
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :reload, resources(:service => "apache2")
    end
  
    apache_site "#{deploy_config["id"]}.conf"
  
  end
  
end