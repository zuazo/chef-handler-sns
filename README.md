Description
===========

A simple Chef report handler that reports status of a Chef run through Amazon SNS.

* http://wiki.opscode.com/display/chef/Exception+and+Report+Handlers

Requirements
============

* Amazon AWS: uses Amazon SNS service.
* Uses the `right_aws` library.

Usage
=====

You can install this handler in two ways:

### Method 1: In the Chef config file

You can install the RubyGem and configure Chef to use it:

    gem install chef-handler-sns

Then add to the configuration (`/etc/chef/solo.rb` for chef-solo or `/etc/chef/client.rb` for chef-client):

    require "chef/handler/sns"
    
    # Create the handler
    sns_handler = Chef::Handler::Sns.new
    
    # Your Amazon AWS credentials
    sns_handler.access_key = "***AMAZON-KEY***"
    sns_handler.secret_key = "***AMAZON-SECRET***"
    
    # Some Amazon SNS configurations
    sns_handler.topic_arn = "arn:aws:sns:***"
    sns_handler.region = "us-east-1" # optional
    
    # Add your handler
    exception_handlers << sns_handler

### Method 2: In a recipe with the chef_handler LWRP

Use the [chef_handler LWRP](http://community.opscode.com/cookbooks/chef_handler), creating a recipe with the following:

    # Handler configuration options
    argument_array = [
      :access_key => "***AMAZON-KEY***",
      :secret_key => "***AMAZON-SECRET***",

      :topic_arn => "arn:aws:sns:***",
      :region => "us-east-1" # optional
    ]
    
    # Install the `chef-handler-sns` RubyGem during the compile phase
    chef_gem "chef-handler-sns"
    
    # Then activate the handler with the `chef_handler` LWRP
    chef_handler "Chef::Handler::Sns" do
      source "#{Gem::Specification.find_by_name("chef-handler-sns").lib_dirs_glob}/chef/handler/sns"
      arguments argument_array
      supports :exception => true
      action :enable
    end

If you have an old version of gem package (< 1.8.6) without `find_by_name` or old chef-client (< 0.10.10) without `chef_gem`, you can try creating a recipe similar to the following:

    # Handler configuration options
    argument_array = [
      :access_key => "***AMAZON-KEY***",
      :secret_key => "***AMAZON-SECRET***",

      :topic_arn => "arn:aws:sns:***",
      :region => "us-east-1" # optional
    ]
    
    # Install the `chef-handler-sns` RubyGem during the compile phase
    if defined?(Chef::Resource::ChefGem)
      chef_gem "chef-handler-sns"
    else
      gem_package("chef-handler-sns") do
        action :nothing
      end.run_action(:install)
    end
    
    # Get the installed `chef-handler-sns` gem path
    sns_handler_path = Gem::Specification.respond_to?("find_by_name") ?
      Gem::Specification.find_by_name("chef-handler-sns").lib_dirs_glob :
      Gem.all_load_paths.grep(/chef-handler-sns/).first
    
    # Then activate the handler with the `chef_handler` LWRP
    chef_handler "Chef::Handler::Sns" do
      source "#{sns_handler_path}/chef/handler/sns"
      arguments argument_array
      supports :exception => true
      action :enable
    end

Roadmap
=======

* rspec tests.

Pull requests are welcome.

License and Author
==================

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Xabier de Zuazo (<xabier@onddo.com>)
| **Copyright:**       | Copyright (c) 2013 Onddo Labs, SL.
| **License:**         | Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

