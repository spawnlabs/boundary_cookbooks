action :deploy do
  
  if new_resource.respond_to?('app_options')
    app_options = new_resource.app_options
  else
    app_options = nil
  end
    
  deploy_config = data_bag_item("apps", new_resource.name)
  
  if deploy_config["type"] == "ruby"

    install_standard_ruby_dependencies new_resource.name do
      deploy_config deploy_config
    end
    
    #
    # base ruby app install
    #
    
    create_user_group_home new_resource.name do
      deploy_config deploy_config
    end
    
    install_app_dependencies new_resource.name do
      deploy_config deploy_config
    end
        
    chown_install_directory new_resource.name do
      deploy_config deploy_config
    end
     
    log_directory new_resource.name do
      deploy_config deploy_config
    end
    
    additional_directories new_resource.name do
      deploy_config deploy_config
    end
    
    additional_configs new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end
    
    additional_binaries new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end
    
    setup_runit_service new_resource.name do
      deploy_config deploy_config
    end
            
    #
    # general config
    #
    
    start_script new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end
    
    setup_main_config_yml new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end
    
    #
    # git deploy
    #
    
    git_setup new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end
    
    git_deploy_ruby new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end
    
    bundle_install new_resource.name do
      deploy_config deploy_config
    end
    
    unicorn_config new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end
    
    iptables new_resource.name do
      deploy_config deploy_config
    end    
    
  else
    log "#{new_resource.name} app is not of type ruby, not deploying"
  end

end
