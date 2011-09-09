#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: jenkins
# Definition:: jenksins_plugin
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

define :jenkins_plugin, :name => nil do
  
  jenkins params[:name] do
    action :install_plugin
    cli_jar "/var/run/jenkins/war/WEB-INF/jenkins-cli.jar"
    url "http://localhost:8080"
    path "/var/lib/jenkins"
    notifies :restart, resources(:service => "jenkins")
  end
  
end
