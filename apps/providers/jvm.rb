#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: apps
# Provider:: jvm
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

action :deploy do

  if new_resource.respond_to?('app_options')
    app_options = new_resource.app_options
  else
    app_options = nil
  end

  deploy_config = data_bag_item("apps", new_resource.name)

  if deploy_config["type"] == "jvm"

    install_standard_jvm_dependencies new_resource.name do
      deploy_config deploy_config
    end

    #
    # base jvm app install
    #

    create_user_group_home new_resource.name do
      deploy_config deploy_config
    end

    install_app_dependencies new_resource.name do
      deploy_config deploy_config
    end

    setup_jvm_application_directories new_resource.name do
      deploy_config deploy_config
    end

    setup_runit_service new_resource.name do
      deploy_config deploy_config
    end

    install_jvm_release new_resource.name do
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

    #
    # general config
    #

    start_script new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end

    setup_log4j_config new_resource.name do
      deploy_config deploy_config
      app_options app_options
    end

    iptables new_resource.name do
      deploy_config deploy_config
    end

    new_resource.updated_by_last_action(true)
  else
    log "#{new_resource.name} app is not of type jvm, not deploying"
  end

end