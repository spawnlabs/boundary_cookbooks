#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: jenkins
# Definition:: jenksins_job
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

define :jenkins_job, :name => nil do
  
  jenkins params[:name] do
    action :create_job
    cli_jar "/var/run/jenkins/war/WEB-INF/jenkins-cli.jar"
    url "http://localhost:8080"
    path "/var/lib/jenkins"
  end
  
  template "/var/lib/jenkins/jobs/#{params[:name]}/config.xml" do
    source "jobs/#{params[:name]}.xml.erb"
    owner "jenkins"
    group "nogroup"
    ignore_failure true
    notifies :restart, resources(:service => "jenkins")
  end
  
end