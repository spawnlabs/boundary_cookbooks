#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: jenkins
# Recipe:: example
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


# this will setup a new job with a blank config
# if you want your own config rewrite the config and 
# reload the configuration from disk using this provider

# wrapped up in a definition
jenkins_job "job"

# delete a job

jenkins "job" do
  action :delete_job
  cli_jar "/var/run/jenkins/war/WEB-INF/jenkins-cli.jar"
  url "http://localhost:8080"
  path "/var/lib/jenkins"
end

# install a plugin
# dont forget, plugin installs require a restart

# wrapped up in a definition
jenkins_plugin "scp"