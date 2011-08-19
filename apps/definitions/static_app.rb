define :static_app, :name => nil, :app_options => nil do

  include_recipe "git"
  
  deploy_config = data_bag_item("apps", params[:name])
  
  if deploy_config["type"] == "static"
    
    #
    # user and group
    #
    
    group deploy_config["system"]["group"] do
      gid deploy_config["system"]["gid"]
    end
    
    user deploy_config["system"]["user"] do
      uid deploy_config["system"]["uid"]
      gid deploy_config["system"]["gid"]
      home deploy_config["system"]["home"]
      shell "/bin/bash"
      system true
    end
    
    directory deploy_config["system"]["home"] do
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode    0700
    end
    
    #
    # install dependencies
    #
    
    if deploy_config["dependencies"]
      if deploy_config["dependencies"]["recipes"]
        deploy_config["dependencies"]["recipes"].each do |dep|
          include_recipe dep
        end
      end
      
      if deploy_config["dependencies"]["system"]
        deploy_config["dependencies"]["system"].each do |dep|
          package dep
        end
      end
    end
    
    
    #
    # setup config dir
    #
    
    directory "#{deploy_config["install"]["path"]}/etc" do
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode    0755
      recursive true
    end
    
    bash "#{deploy_config["install"]["path"]} permissions" do
      user "root"
      cwd "/opt"
      code <<-EOH
      (chown -R #{deploy_config["system"]["user"]}:#{deploy_config["system"]["group"]} #{deploy_config["install"]["path"]})
      EOH
    end
    
    #
    # setup additional directories
    #
    
    if deploy_config["config"]["additional_directories"]
      deploy_config["config"]["additional_directories"].each do |dir|
        directory dir do
          owner   deploy_config["system"]["user"]
          group   deploy_config["system"]["group"]
          mode    0755
          recursive true
        end
      end
    end
    
    #
    # ssh and git keys
    #

    template "#{deploy_config["install"]["path"]}/etc/git_ssh.sh" do
      source  "static/git_ssh.sh.erb"
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode    0755
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
    end
    
    %w[ gitconfig deploy_key deploy_key.pub ].each do |filename|
      template "#{deploy_config["install"]["path"]}/etc/#{filename}" do
        source  "static/#{filename}.erb"
        owner   deploy_config["system"]["user"]
        group   deploy_config["system"]["group"]
        mode    0600
        variables :deploy_config => deploy_config, :app_options => params[:app_options]
      end
    end
        
    #
    # git deploy
    #
    
    git "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}" do
      repository  deploy_config["config"]["git"]["repository"]
      reference   deploy_config["config"]["git"]["reference"]
      action      :sync
      ssh_wrapper "#{deploy_config["install"]["path"]}/etc/git_ssh.sh"
    end
    
    if deploy_config["config"]["webserver"] == "nginx"
      
      include_recipe "nginx"
    
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
    
      include_recipe "apache2"
      
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
    
  else
    log "#{params[:name]} app is not of type static, not deploying"
  end
  
end