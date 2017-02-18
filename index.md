# Chef Handler SNS
[![Gem Version](http://img.shields.io/gem/v/chef-handler-sns.svg?style=flat)](http://badge.fury.io/rb/chef-handler-sns)
[![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg?style=flat)](http://www.rubydoc.info/gems/chef-handler-sns)
[![GitHub](http://img.shields.io/badge/github-zuazo/chef--handler--sns-blue.svg?style=flat)](https://github.com/zuazo/chef-handler-sns)
[![License](https://img.shields.io/github/license/zuazo/chef-handler-sns.svg?style=flat)](#license-and-author)

[![Dependency Status](http://img.shields.io/gemnasium/zuazo/chef-handler-sns.svg?style=flat)](https://gemnasium.com/zuazo/chef-handler-sns)
[![Code Climate](http://img.shields.io/codeclimate/github/zuazo/chef-handler-sns.svg?style=flat)](https://codeclimate.com/github/zuazo/chef-handler-sns)
[![Build Status](http://img.shields.io/travis/zuazo/chef-handler-sns/2.1.0.svg?style=flat)](https://travis-ci.org/zuazo/chef-handler-sns)
[![Coverage Status](http://img.shields.io/coveralls/zuazo/chef-handler-sns/2.1.0.svg?style=flat)](https://coveralls.io/r/zuazo/chef-handler-sns?branch=2.1.0)
[![Inline docs](http://inch-ci.org/github/zuazo/chef-handler-sns.svg?branch=master&style=flat)](http://inch-ci.org/github/zuazo/chef-handler-sns)

A simple Chef report handler that reports status of a Chef run through [Amazon SNS](http://aws.amazon.com/sns/), [including IAM roles support](#usage-with-amazon-iam-roles).

[Amazon SNS](http://aws.amazon.com/sns/) can send notifications by SMS, email, [Amazon SQS](http://aws.amazon.com/sqs/) queues or to any HTTP endpoint.

We recommend using the [`chef_handler_sns` cookbook](https://supermarket.chef.io/cookbooks/chef_handler_sns) for easy installation.

This Chef Handler is heavily based on [Joshua Timberman](https://github.com/jtimberman) examples.

* https://docs.chef.io/handlers.html#exception-report-handlers

## Requirements

* Amazon AWS: uses Amazon SNS service.
* Ruby `2` or higher (recommended `2.1` or higher).

## Usage

You can install this handler in two ways:

### Method 1: in the Chef Config File

You can install the RubyGem and configure Chef to use it:

    $ gem install chef-handler-sns

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

### Method 2: in a Recipe with the `chef_handler` LWRP

**Note:** This method will not catch errors before the convergence phase. Use the previous method if you want to be able to report such errors.

Use the [`chef_handler` LWRP](https://supermarket.chef.io/cookbooks/chef_handler), creating a recipe with the following:

```ruby
# Handler configuration options
argument_array = [
  access_key: '***AMAZON-KEY***',
  secret_key: '***AMAZON-SECRET***',
  topic_arn: 'arn:aws:sns:***'
]

# Install the `chef-handler-sns` RubyGem during the compile phase
chef_gem 'chef-handler-sns' do
  compile_time true # Only for Chef 12
end

# Then activate the handler with the `chef_handler` LWRP
chef_handler 'Chef::Handler::Sns' do
  source 'chef/handler/sns'
  arguments argument_array
  supports exception: true
  action :enable
end
```

See the [`chef_handler_sns` cookbook provider code](https://github.com/zuazo/chef_handler_sns-cookbook/blob/master/providers/default.rb) for a more complete working example.

### Method 3: Using the `chef-client` Cookbook

You can also use the `node['chef_client']['config']` attribute of the [`chef-client`](https://github.com/chef-cookbooks/chef-client/tree/v4.3.2#start-report-exception-handlers) cookbook:

```ruby
node.default['chef_client']['config']['exception_handlers'] = [{
  'class' => 'Chef::Handler::Sns',
  'arguments' => {
    access_key: '***AMAZON-KEY***',
    secret_key: '***AMAZON-SECRET***',
    topic_arn: 'arn:aws:sns:***'
  }.map { |k, v| "#{k}: #{v.inspect}" }
}]
```

### Usage with Amazon IAM Roles

If you are using AWS [IAM roles](http://docs.aws.amazon.com/IAM/latest/UserGuide/WorkingWithRoles.html) with your server, probably you only need to specify the `topic_arn` parameter. A few simple examples:

#### IAM Roles Method 1: in the Chef Config File

You can install the RubyGem and configure Chef to use it:

    $ gem install chef-handler-sns

Then add to the configuration (`/etc/chef/solo.rb` for chef-solo or `/etc/chef/client.rb` for chef-client):

```ruby
require 'chef/handler/sns'

exception_handlers << Chef::Handler::Sns.new(
  topic_arn: 'arn:aws:sns:us-east-1:12341234:MyTopicName'
)
```

#### IAM Roles Method 2: in a Recipe with the `chef_handler` LWRP

Use the [`chef_handler` LWRP](https://supermarket.chef.io/cookbooks/chef_handler), creating a recipe with the following:

```ruby
# Install the `chef-handler-sns` RubyGem during the compile phase
chef_gem 'chef-handler-sns' do
  compile_time true # Only for Chef 12
end

# Then activate the handler with the `chef_handler` LWRP
chef_handler 'Chef::Handler::Sns' do
  source 'chef/handler/sns'
  arguments topic_arn: 'arn:aws:sns:us-east-1:12341234:MyTopicName'
  supports exception: true
  action :enable
end
```

### IAM Roles Method 3: Using the `chef-client` Cookbook

You can also use the `node['chef_client']['config']` attribute of the [`chef-client`](https://github.com/chef-cookbooks/chef-client/tree/v4.3.2#start-report-exception-handlers) cookbook:

```ruby
node.default['chef_client']['config']['exception_handlers'] = [{
  'class' => 'Chef::Handler::Sns',
  'arguments' => ['topic_arn: "arn:aws:sns:***"']
}]
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

* `access_key` - AWS access key (required, but will try to read it from Ohai with IAM roles).
* `secret_key` - AWS secret key (required, but will try to read it from Ohai with IAM roles).
* `token` - AWS security token (optional, read from Ohai with IAM roles). Set to `false` to disable the token detected by Ohai.
* `topic_arn` - AWS topic ARN name (required).
* `message_structure` - Set this option to `json` if you want to send a different message for each protocol. You must set your [message body template](#body_template-configuration-option) properly. Valid value: `json` (optional).
* `region` - AWS region (optional).
* `subject` - Message subject string in erubis format (optional).
* `body_template` - Full path of an erubis template file to use for the message body (optional).
* `filter_opsworks_activities` - An array of OpsWorks activities to be triggered with (optional). When set, everything else will be discarded.

**Note:** When the machine has an IAM role, will try to read the credentials from Ohai. So in the best case, you only need to specify the `topic_arn`.

### `subject` Configuration Option

Here is an example of the `subject` configuration option using the ruby configuration file (`solo.rb` or `client.rb`):

```ruby
sns_handler.subject(
  "Chef-run: <%= node.name %> - <%= run_status.success? ? 'ok' : 'error' %>"
)
```

Using the [`chef_handler` LWRP](https://supermarket.chef.io/cookbooks/chef_handler):

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
* `all_resources` - An Array containing all resources in the chef-run resource collection.
* `updated_resources` - An Array containing all resources that were updated during the chef run.
* `success?` - Was the chef run successful? True if the chef run did not raise an uncaught exception.
* `failed?` - Did the chef run fail? True if the chef run raised an uncaught exception.

### `body_template` Configuration Option

This configuration option needs to contain the full path of an Erubis template. For example:

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

If you set `message_structure` to `json`, the body template must:

* be a syntactically valid JSON; and
* contain at least a top-level JSON key of `default` with a value that is a string.

You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").
```erb
<%# file 'myapp/files/default/chef_handler_sns_body.erb' %>
{
"default": "Message body text here.", 
"email": "Message body text here.", 
"http": "Message body text here."
}
```
See the [AWS SNS](http://docs.aws.amazon.com/sns/latest/api/API_Publish.html#API_Publish_RequestParameters) documentation for more details on SNS message format.

## IAM Role Credentials from Ohai

IAM Role information and credentials are gathered from Ohai by default if they exists.

No aditional Ohai plugin is required. This is natively supported by Ohai since version `6.16.0` ([OHAI-400](https://tickets.opscode.com/browse/OHAI-400)).

These are the used Ohai attributes:

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

## Testing

See [TESTING.md](https://github.com/zuazo/chef-handler-sns/blob/master/TESTING.md).

## Contributing

Please do not hesitate to [open an issue](https://github.com/zuazo/chef-handler-sns/issues/new) with any questions or problems.

See [CONTRIBUTING.md](https://github.com/zuazo/chef-handler-sns/blob/master/CONTRIBUTING.md).

## TODO

See [TODO.md](https://github.com/zuazo/chef-handler-sns/blob/master/TODO.md).

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
    
