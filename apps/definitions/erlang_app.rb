define :erlang_app, :name => nil, :app_options => nil, :post_upgrade_service_action => :nothing, :upgrade_code => nil do
  
  include_recipe "runit"
  
  deploy_config = data_bag_item("apps", params[:name])

  if deploy_config["type"] == "erlang"
  
    #
    # erlang bits
    #
    
    include_recipe "erlang::erl_call"
    include_recipe "erlang::epmd"
    
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
    # base install
    #
    
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
    
    bash "#{deploy_config["install"]["path"]} permissions" do
      user "root"
      cwd "/opt"
      code <<-EOH
      (chown -R #{deploy_config["system"]["user"]}:#{deploy_config["system"]["group"]} #{deploy_config["install"]["path"]})
      EOH
    end
    
    #
    # setup runit service
    #
    
    runit_service "#{deploy_config["id"]}" do
      template_name "app"
      options deploy_config
    end
    
    service "#{deploy_config["id"]}" do
      supports :status => true, :restart => true
      action [ :start ]
    end
    
    #
    # setup log dir
    #
    
    directory "/var/log/#{deploy_config["id"]}" do
      owner deploy_config["system"]["user"]
      group deploy_config["system"]["group"]
    end
    
    #
    # setup additional directories
    #
    
    if deploy_config["config"]["additional_directories"]
      deploy_config["config"]["additional_directories"].each do |dir|
        directory dir do
          owner deploy_config["system"]["user"]
          group deploy_config["system"]["group"]
          mode 0755
          recursive true
        end
      end
    end
    
    #
    # general config
    #
    
    # the start script
    template "#{deploy_config["install"]["path"]}/bin/#{deploy_config["id"]}" do
      source "erlang/#{deploy_config["id"]}/#{deploy_config["id"]}.erb"
      owner deploy_config["system"]["user"]
      group deploy_config["system"]["group"]
      mode 0755
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :restart, resources(:service => "#{deploy_config["id"]}")
    end
    
    # erlang main config
    template "#{deploy_config["install"]["path"]}/etc/#{deploy_config["id"]}.config" do
      source "#{deploy_config["type"]}/#{deploy_config["id"]}/config.erb"
      owner deploy_config["system"]["user"]
      group deploy_config["system"]["group"]
      mode 0644
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :restart, resources(:service => "#{deploy_config["id"]}")
    end
    
    # erlang sys config
    template "#{deploy_config["install"]["path"]}/releases/#{deploy_config["version"]}/sys.config" do
      source "#{deploy_config["type"]}/#{deploy_config["id"]}/config.erb"
      owner deploy_config["system"]["user"]
      group deploy_config["system"]["group"]
      mode 0644
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
    end
    
    # erlang vm.args
    template "#{deploy_config["install"]["path"]}/etc/vm.args" do
      source "#{deploy_config["type"]}/vm.args.erb"
      owner deploy_config["system"]["user"]
      group deploy_config["system"]["group"]
      mode 0644
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :restart, resources(:service => "#{deploy_config["id"]}")
    end
    
    # for any configs listed in the databag
    if deploy_config["config"]["additional_config_templates"]
      deploy_config["config"]["additional_config_templates"].each do |config|
        template "#{deploy_config["install"]["path"]}/etc/#{config}" do
          source "#{deploy_config["type"]}/#{deploy_config["id"]}/#{config}.erb"
          owner deploy_config["system"]["user"]
          group deploy_config["system"]["group"]
          mode 0644
          variables :deploy_config => deploy_config, :app_options => params[:app_options]
          notifies :restart, resources(:service => "#{deploy_config["id"]}")
        end
      end
    end
    
    # other bins listed in the databag
    if deploy_config["config"]["additional_bin_templates"]
      deploy_config["config"]["additional_bin_templates"].each do |config|
        template "#{deploy_config["install"]["path"]}/bin/#{config}" do
          source "#{deploy_config["type"]}/#{deploy_config["id"]}/#{config}.erb"
          owner deploy_config["system"]["user"]
          group deploy_config["system"]["group"]
          mode 0755
          variables :deploy_config => deploy_config, :app_options => params[:app_options]
        end
      end
    end
    
    #
    # upgrade stuff
    #
    
    remote_file "#{deploy_config["install"]["path"]}/releases/#{filename}" do
      source "#{deploy_config["install"]["repo_url"]}/#{deploy_config["id"]}/upgrades/#{filename}"
      not_if "/usr/bin/test -d #{deploy_config["install"]["path"]}/releases/#{deploy_config["version"]}"
    end
    
    if params[:upgrade_code].nil?
      upgrade_code = <<-EOH
      release_handler:unpack_release("#{deploy_config["id"]}_#{deploy_config["version"]}"),
      release_handler:install_release("#{deploy_config["version"]}"),
      release_handler:make_permanent("#{deploy_config["version"]}").
      EOH
    else
      upgrade_code = params[:upgrade_code]
    end
    
    erl_call "upgrade #{deploy_config["id"]}" do
      node_name "#{deploy_config["id"]}@#{node[:fqdn]}"
      name_type "name"
      cookie deploy_config["erlang"]["cookie"]
      code upgrade_code
      not_if "/usr/bin/test -d #{deploy_config["install"]["path"]}/releases/#{deploy_config["version"]}"
      notifies params[:post_upgrade_service_action], resources("service" => deploy_config["id"])
    end
    
    #
    # iptables if needed
    #
    
    if deploy_config["config"]["iptables"]
      iptables_rule "10#{deploy_config["id"]}" do
        source "#{deploy_config["type"]}/#{deploy_config["id"]}/iptables_rules.erb"
      end
    end
    
  else
    log "#{params[:name]} app is not of type erlang, not deploying"
  end
  
end