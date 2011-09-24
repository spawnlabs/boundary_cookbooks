action :deploy do
  
  if new_resource.respond_to?('app_options')
    app_options = new_resource.app_options
  else
    app_options = nil
  end
  
  deploy_config = data_bag_item("apps", new_resource.name)

  if deploy_config["type"] == "erlang"

    install_standard_erlang_dependencies new_resource.name do
      deploy_config deploy_config
    end
    
    #
    # base erlang app install
    #
    
    create_user_group_home new_resource.name do
      deploy_config deploy_config
    end
    
    install_app_dependencies new_resource.name do
      deploy_config deploy_config
    end
    
    install_erlang_release new_resource.name do
      deploy_config deploy_config
    end
    
    chown_install_directory new_resource.name do
      deploy_config deploy_config
    end
        
    setup_runit_service new_resource.name do
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
    
    #
    # general config
    #
    
    start_script new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end
    
    erlang_config new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end
    
    erlang_vm_args new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end
    
    if new_resource.respond_to?('upgrade_code')
       upgrade_code = new_resource.upgrade_code
     else
       upgrade_code = nil
     end
    
    erlang_hot_upgrade new_resource.name do
      deploy_config deploy_config
      post_upgrade_service_action post_upgrade_service_action
      upgrade_code upgrade_code
    end
    
    iptables new_resource.name do
      deploy_config deploy_config
    end
    
  else
    log "#{new_resource.name} app is not of type erlang, not deploying"
  end
  
end