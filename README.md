# Chef Handler SNS
[![GitHub](http://img.shields.io/badge/github-zuazo/chef-handler-sns-blue.svg?style=flat)](https://github.com/zuazo/chef-handler-sns)
[![License](https://img.shields.io/github/license/zuazo/chef-handler-sns.svg?style=flat)](#license-and-author)

[![Gem Version](https://badge.fury.io/rb/chef-handler-sns.svg)](https://rubygems.org/gems/chef-handler-sns)
[![Dependency Status](http://img.shields.io/gemnasium/zuazo/chef-handler-sns.svg?style=flat)](https://gemnasium.com/zuazo/chef-handler-sns)
[![Code Climate](http://img.shields.io/codeclimate/github/zuazo/chef-handler-sns.svg?style=flat)](https://codeclimate.com/github/zuazo/chef-handler-sns)
[![Build Status](http://img.shields.io/travis/zuazo/chef-handler-sns.svg?style=flat)](https://travis-ci.org/zuazo/chef-handler-sns)
[![Coverage Status](http://img.shields.io/coveralls/zuazo/chef-handler-sns.svg?style=flat)](https://coveralls.io/r/zuazo/chef-handler-sns?branch=master)

A simple Chef report handler that reports status of a Chef run through [Amazon SNS](http://aws.amazon.com/sns/), [including IAM roles support](#usage-with-amazon-iam-roles).

[Amazon SNS](http://aws.amazon.com/sns/) can send notifications by SMS, email, [Amazon SQS](http://aws.amazon.com/sqs/) queues or to any HTTP endpoint.

We recommend using the [chef_handler_sns cookbook](https://supermarket.chef.io/cookbooks/chef_handler_sns) for easy installation.

This Chef Handler is heavily based on [Joshua Timberman](https://github.com/jtimberman) examples.

* https://docs.chef.io/handlers.html#exception-report-handlers

## Requirements

* Amazon AWS: uses Amazon SNS service.
* Uses the `aws-sdk` library.
  * `aws-sdk` requires `nokogiri`, which also has the following requirements:
    * `libxml2-dev` and `libxslt-dev` installed (optional).
    * `gcc` and `make` installed (this will compile and install libxml2 and libxslt internally if not found).
* Ruby `2` or higher (recommended `2.1` or higher).

## Usage

You can install this handler in two ways:

### Method 1: in the Chef Config File

You can install the RubyGem and configure Chef to use it:

    gem install chef-handler-sns

Then add to the configuration (`/etc/chef/solo.rb` for chef-solo or `/etc/chef/client.rb` for chef-client):

```ruby
require 'chef/handler/sns'

# Create the handler
sns_handler = Chef::Handler::Sns.new

# Your Amazon AWS credentials
sns_handler.access_key '***AMAZON-KEY***'
sns_handler.secret_key '***AMAZON-SECRET***'

# Some Amazon SNS configurations
sns_handler.topic_arn 'arn:aws:sns:***'
sns_handler.region 'us-east-1' # optional

# Add your handler
exception_handlers << sns_handler
```

### Method 2: in a Recipe with the chef_handler LWRP

**Note:** This method will not catch errors before the convergence phase. Use the previous method if you want to be able to report such errors.

Use the [chef_handler LWRP](https://supermarket.chef.io/cookbooks/chef_handler), creating a recipe with the following:

```ruby
# Handler configuration options
argument_array = [
  access_key: '***AMAZON-KEY***',
  secret_key: '***AMAZON-SECRET***',
  topic_arn: 'arn:aws:sns:***'
]

# Depends on the `xml` cookbook to install nokogiri
include_recipe 'xml::ruby'

# Install the `chef-handler-sns` RubyGem during the compile phase
chef_gem 'chef-handler-sns'

# Then activate the handler with the `chef_handler` LWRP
chef_handler 'Chef::Handler::Sns' do
  source(::File.join(
           Gem::Specification.find_by_name('chef-handler-sns').lib_dirs_glob,
           'chef/handler/sns'
  ))
  arguments argument_array
  supports exception: true
  action :enable
end
```

#### Method 2.1: in a Recipe with the chef_handler LWRP Using Gem < 1.8.6

If you have an old version of gem package (< 1.8.6) without `find_by_name` or old chef-client (< 0.10.10) without `chef_gem`, you can try creating a recipe similar to the following:

```ruby
# Handler configuration options
argument_array = [
  access_key: '***AMAZON-KEY***',
  secret_key: '***AMAZON-SECRET***',
  topic_arn: 'arn:aws:sns:***'
]

# Depends on the `xml` cookbook to install nokogiri
include_recipe 'xml::ruby'

# Install the `chef-handler-sns` RubyGem during the compile phase
if defined?(Chef::Resource::ChefGem)
  chef_gem 'chef-handler-sns'
else
  gem_package('chef-handler-sns') do
    action :nothing
  end.run_action(:install)
end

# Get the installed `chef-handler-sns` gem path
sns_handler_path =
  if Gem::Specification.respond_to?('find_by_name')
    Gem::Specification.find_by_name('chef-handler-sns').lib_dirs_glob
  else
    Gem.all_load_paths.grep(/chef-handler-sns/).first
  end

# Then activate the handler with the `chef_handler` LWRP
chef_handler 'Chef::Handler::Sns' do
  source "#{sns_handler_path}/chef/handler/sns"
  arguments argument_array
  supports exception: true
  action :enable
end
```

#### Method 2.2: in a Recipe with the chef_handler LWRP Inside AWS OpsWorks

If you are inside [AWS OpsWorks](http://aws.amazon.com/opsworks/) or running Chef inside _Bundler_, you might receive the following error:

    Gem::LoadError
    --------------
    Could not find 'chef-handler-sns' (>= 0) among XX total gem(s)

To fix this error, you should get the handler installation path using a code similar to the following:

```ruby
# Handler configuration options
argument_array = [
  access_key: '***AMAZON-KEY***',
  secret_key: '***AMAZON-SECRET***',
  topic_arn: 'arn:aws:sns:***'
]

# Depends on the `xml` cookbook to install nokogiri
include_recipe 'xml::ruby'

# Install the `chef-handler-sns` RubyGem during the compile phase
chef_gem 'chef-handler-sns'

# Get the installed `chef-handler-sns` gem path from Bundler
sns_handler_path = nil
bundle_path = ::File.join(Bundler.bundle_path.to_s, 'specifications')
Dir[::File.join(bundle_path, '*.gemspec')].each do |path|
  spec = Gem::Specification.load(path.untaint)
  sns_handler_path = spec.lib_dirs_glob if spec.name == 'chef-handler-sns'
end
if sns_handler_path.nil?
  Chef::Application.fatal!(
    "chef-handler-sns not found inside Bundler path: #{bundle_path}"
  )
end

# Then activate the handler with the `chef_handler` LWRP
chef_handler 'Chef::Handler::Sns' do
  source(::File.join(
           Gem::Specification.find_by_name('chef-handler-sns').lib_dirs_glob,
           'chef/handler/sns'
  ))
  arguments argument_array
  supports exception: true
  action :enable
end
```

See the [`chef_handler_sns` cookbook provider code](https://github.com/zuazo/chef_handler_sns-cookbook/blob/master/providers/default.rb) for a more complete working example.

### Usage with Amazon IAM Roles

If you are using AWS [IAM roles](http://docs.aws.amazon.com/IAM/latest/UserGuide/WorkingWithRoles.html) with your server, probably you only need to specify the `topic_arn` parameter. A few simple examples:

#### Method 1: in the Chef Config File

You can install the RubyGem and configure Chef to use it:

    gem install chef-handler-sns

Then add to the configuration (`/etc/chef/solo.rb` for chef-solo or `/etc/chef/client.rb` for chef-client):

```ruby
require 'chef/handler/sns'

exception_handlers << Chef::Handler::Sns.new(
  topic_arn: 'arn:aws:sns:us-east-1:12341234:MyTopicName'
)
```

#### Method 2: in a Recipe with the chef_handler LWRP

Use the [chef_handler LWRP](https://supermarket.chef.io/cookbooks/chef_handler), creating a recipe with the following:

```ruby
# Depends on the `xml` cookbook to install nokogiri
include_recipe 'xml::ruby'

# Install the `chef-handler-sns` RubyGem during the compile phase
chef_gem 'chef-handler-sns'

# Then activate the handler with the `chef_handler` LWRP
chef_handler 'Chef::Handler::Sns' do
  source(::File.join(
           Gem::Specification.find_by_name('chef-handler-sns').lib_dirs_glob,
           'chef/handler/sns'
  ))
  arguments(topic_arn: 'arn:aws:sns:us-east-1:12341234:MyTopicName')
  supports exception: true
  action :enable
end
```

#### OpsWorks: Filter Notifications by Activity
An optional array of OpsWorks activities can be supplied. If the array is set, notifications will
only be triggered for the activities in the array, everything else will be discarded.

```ruby
argument_array = [
  filter_opsworks_activities: %w(deploy configure)
]
```

## Handler Configuration Options

The following options are available to configure the handler:

* `access_key` - AWS access key (required, but will try to read it from ohai with IAM roles).
* `secret_key` - AWS secret key (required, but will try to read it from ohai with IAM roles).
* `token` - AWS security token (optional, read from ohai with IAM roles). Set to `false` to disable the token detected by ohai.
* `topic_arn` - AWS topic ARN name (required).
* `region` - AWS region (optional).
* `subject` - Message subject string in erubis format (optional).
* `body_template` - Full path of an erubis template file to use for the message body (optional).
* `filter_opsworks_activities` - An array of OpsWorks activities to be triggered with (optional). When set, everything else will be discarded.

**Note:** When the machine has an IAM role, will try to read the credentials from ohai. So in the best case, you only need to specify the `topic_arn`.

### subject

Here is an example of the `subject` configuration option using the ruby configuration file (`solo.rb` or `client.rb`):

```ruby
sns_handler.subject(
  "Chef-run: <%= node.name %> - <%= run_status.success? ? 'ok' : 'error' %>"
)
```

Using the [chef_handler LWRP](https://supermarket.chef.io/cookbooks/chef_handler):
```ruby
argument_array = [
  access_key: '***AMAZON-KEY***',
  secret_key: '***AMAZON-SECRET***',
  topic_arn: 'arn:aws:sns:***',
  subject:
    "Chef-run: <%= node.name %> - <%= run_status.success? ? 'ok' : 'error' %>"
  # [...]
]
chef_handler 'Chef::Handler::Sns' do
  # [...]
  arguments argument_array
end
```

The following variables are accessible inside the template:

* `start_time` - The time the chef run started.
* `end_time` - The time the chef run ended.
* `elapsed_time` - The time elapsed between the start and finish of the chef run.
* `run_context` - The Chef::RunContext object used by the chef run.
* `exception` - The uncaught Exception that terminated the chef run, or nil if the run completed successfully.
* `backtrace` - The backtrace captured by the uncaught exception that terminated the chef run, or nil if the run completed successfully.
* `node` - The Chef::Node for this client run.
* `all_resources` - An Array containing all resources in the chef-run's resource_collection.
* `updated_resources` - An Array containing all resources that were updated during the chef run.
* `success?` - Was the chef run successful? True if the chef run did not raise an uncaught exception.
* `failed?` - Did the chef run fail? True if the chef run raised an uncaught exception.

### body_template

This configuration option needs to contain the full path of an erubis template. For example:

```ruby
# recipe 'myapp::sns_handler'

cookbook_file 'chef_handler_sns_body.erb' do
  path '/tmp/chef_handler_sns_body.erb'
  # [...]
end

argument_array = [
  access_key: '***AMAZON-KEY***',
  secret_key: '***AMAZON-SECRET***',
  topic_arn: 'arn:aws:sns:***',
  body_template: '/tmp/chef_handler_sns_body.erb'
  # [...]
]
chef_handler 'Chef::Handler::Sns' do
  # [...]
  arguments argument_array
end
```

```erb
<%# file 'myapp/files/default/chef_handler_sns_body.erb' %>

Node Name: <%= node.name %>
<% if node.attribute?('fqdn') -%>
Hostname: <%= node.fqdn %>
<% end -%>

Chef Run List: <%= node.run_list.to_s %>
Chef Environment: <%= node.chef_environment %>

<% if node.attribute?('ec2') -%>
Instance Id: <%= node.ec2.instance_id %>
Instance Public Hostname: <%= node.ec2.public_hostname %>
Instance Hostname: <%= node.ec2.hostname %>
Instance Public IPv4: <%= node.ec2.public_ipv4 %>
Instance Local IPv4: <%= node.ec2.local_ipv4 %>
<% end -%>

Chef Client Elapsed Time: <%= elapsed_time.to_s %>
Chef Client Start Time: <%= start_time.to_s %>
Chef Client Start Time: <%= end_time.to_s %>

<% if exception -%>
Exception: <%= run_status.formatted_exception %>
Stacktrace:
<%= Array(backtrace).join("\n") %>

<% end -%>
```

See the [subject](#subject) documentation for more details on the variables accessible inside the template.

## IAM Role Credentials from Ohai

IAM Role information and credentials are gathered from ohai by default if they exists.

No aditional ohai plugin is required. This is natively supported by ohai since version `6.16.0` ([OHAI-400](https://tickets.opscode.com/browse/OHAI-400)).

These are the used ohai attributes:

```
ec2
├── placement_availability_zone: region is set from here.
└── iam
    └── security-credentials
        └── IAMRoleName
            ├── AccessKeyId
            ├── SecretAccessKey
            └── Token
```

## Running the Tests

Minitest tests can be run as usual:

    rake test

## Contributing

1. Fork the repository on Github.
2. Create a named feature branch (like `add_component_x`).
3. Write tests for your change.
4. Write your change.
5. Run the tests, ensuring they all pass (try as much as possible not to reduce coverage).
6. Submit a [Pull Request using Github](http://github.com/zuazo/chef-handler-sns/pulls).

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | [Xabier de Zuazo](https://github.com/zuazo) (<xabier@zuazo.org>)
| **Contributor:**     | [Florian Holzhauer](https://github.com/fh)
| **Contributor:**     | [Michael Hobbs](https://github.com/michaelshobbs)
| **Copyright:**       | Copyright (c) 2015 Xabier de Zuazo
| **Copyright:**       | Copyright (c) 2013-2014 Onddo Labs, SL.
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
    
