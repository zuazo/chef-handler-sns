#
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2015 Xabier de Zuazo
# Copyright:: Copyright (c) 2014 Onddo Labs, SL.
# License:: Apache License, Version 2.0
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

require 'chef/handler'
require 'chef/handler/sns/config'
require 'aws-sdk'
require 'erubis'

class Chef
  #
  # Chef report handlers.
  #
  class Handler
    #
    # Chef Handler SNS main class.
    #
    # A simple Chef report handler that reports status of a Chef run through
    # [Amazon SNS](http://aws.amazon.com/sns/),
    # [including IAM roles support](#usage-with-amazon-iam-roles).
    #
    class Sns < ::Chef::Handler
      #
      # Include {Config.config_init} and {Config.config_check} methods.
      #
      include ::Chef::Handler::Sns::Config

      #
      # Constructs a new `Sns` object.
      #
      # @example `/etc/chef/client.rb` Configuration Example
      #   require 'chef/handler/sns'
      #   sns_handler = Chef::Handler::Sns.new
      #   sns_handler.access_key '***AMAZON-KEY***'
      #   sns_handler.secret_key '***AMAZON-SECRET***'
      #   sns_handler.topic_arn 'arn:aws:sns:***'
      #   sns_handler.region 'us-east-1' # optional
      #   exception_handlers << sns_handler
      #
      # @example `/etc/chef/client.rb` Example Using a Hash for Configuration
      #   require 'chef/handler/sns'
      #   exception_handlers << Chef::Handler::Sns.new(
      #     access_key: '***AMAZON-KEY***',
      #     secret_key: '***AMAZON-SECRET***',
      #     topic_arn: 'arn:aws:sns:***',
      #     region: 'us-east-1' # optional
      #   )
      #
      # @example `/etc/chef/client.rb` Using IAM Roles
      #   require 'chef/handler/sns'
      #   exception_handlers << Chef::Handler::Sns.new(
      #     topic_arn: 'arn:aws:sns:us-east-1:12341234:MyTopicName'
      #   )
      #
      #
      # @example Using the `chef_handler` Cookbook
      #   # Install the `chef-handler-sns` RubyGem during the compile phase
      #   chef_gem 'chef-handler-sns' do
      #     compile_time true # Only for Chef 12
      #   end
      #   # Then activate the handler with the `chef_handler` LWRP
      #   chef_handler 'Chef::Handler::Sns' do
      #     source 'chef/handler/sns'
      #     arguments(
      #       access_key: '***AMAZON-KEY***',
      #       secret_key: '***AMAZON-SECRET***',
      #       topic_arn: 'arn:aws:sns:***'
      #     )
      #     supports exception: true
      #     action :enable
      #   end
      #
      # @example Using the `chef-client` Cookbook
      #   node.default['chef_client']['config']['exception_handlers'] = [{
      #     'class' => 'Chef::Handler::Sns',
      #     'arguments' => {
      #       access_key: '***AMAZON-KEY***',
      #       secret_key: '***AMAZON-SECRET***',
      #       topic_arn: 'arn:aws:sns:***'
      #     }.map { |k, v| "#{k}: #{v.inspect}" }
      #   }]
      #
      # @param config [Hash] Configuration options.
      #
      # @option config [String] :access_key AWS access key (required, but will
      #   try to read it from Ohai with IAM roles).
      # @option config [String] :secret_key AWS secret key (required, but will
      #   try to read it from Ohai with IAM roles).
      # @option config [String] :token AWS security token (optional, read from
      #   Ohai with IAM roles). Set to `false` to disable the token detected by
      #   Ohai.
      # @option config [String] :topic_arn AWS topic ARN name (required).
      # @option config [String] :region AWS region (optional).
      # @option config [String] :subject Message subject string in erubis
      #   format (optional).
      # @option config [String] :body_template Full path of an erubis template
      #   file to use for the message body (optional).
      # @option config [Array] :filter_opsworks_activities An array of
      #   OpsWorks activities to be triggered with (optional). When set,
      #   everything else will be discarded.
      #
      # @api public
      #
      def initialize(config = {})
        Chef::Log.debug("#{self.class} initialized.")
        config_init(config)
      end

      #
      # Send a SNS report message.
      #
      # This is called by Chef internally.
      #
      # @return void
      #
      # @api public
      #
      def report
        config_check(node)
        return unless allow_publish(node)
        sns.publish(
          topic_arn: topic_arn,
          message: sns_body,
          subject: sns_subject
        )
      end

      protected

      #
      # Checks if the message will be published based in configured OpsWorks
      # activities.
      #
      # @param node [Chef::Node] Chef Node that contains the activities.
      #
      # @return [Boolean] Whether the message needs to be sent.
      #
      # @api private
      #
      def allow_publish(node)
        return true if filter_opsworks_activity.nil?

        if node.attribute?('opsworks') &&
           node['opsworks'].attribute?('activity')
          return filter_opsworks_activity.include?(node['opsworks']['activity'])
        end

        Chef::Log.debug(
          'You supplied opsworks activity filters, but node attr was not '\
          'found. Returning false'
        )
        false
      end

      #
      # Returns the {Aws::SNS} object used to send the messages.
      #
      # @return [Aws::SNS::Client] The SNS client.
      def sns
        @sns ||= begin
          params = {
            access_key_id: access_key,
            secret_access_key: secret_key,
            logger: Chef::Log
          }
          params[:region] = region if region
          params[:session_token] = token if token
          Aws::SNS::Client.new(params)
        end
      end

      #
      # Fixes or forces the correct encoding of strings.
      #
      # Replaces wrong characters with `'?'`s.
      #
      # @param o [String, Object] The string to fix.
      # @param encoding [String] The encoding to use.
      #
      # @return [String] The message fixed.
      #
      # @api private
      #
      def fix_encoding(o, encoding)
        encode_opts = { invalid: :replace, undef: :replace, replace: '?' }

        return o.to_s.encode(encoding, encode_opts) if RUBY_VERSION >= '2.1.0'
        # Fix ArgumentError: invalid byte sequence in UTF-8 (issue #7)
        o.to_s.encode(encoding, 'binary', encode_opts)
      end

      #
      # Fixes the encoding of SNS subjects.
      #
      # @param o [String, Object] The subject to fix.
      #
      # @return [String] The message fixed.
      #
      # @api private
      #
      def fix_subject_encoding(o)
        fix_encoding(o, 'ASCII')
      end

      #
      # Fixes the encoding of SNS bodies.
      #
      # @param o [String, Object] The body to fix.
      #
      # @return [String] The message fixed.
      #
      # @api private
      #
      def fix_body_encoding(o)
        fix_encoding(o, 'UTF-8')
      end

      #
      # Returns the SNS subject used by default.
      #
      # @return [String] The SNS subject.
      #
      # @api private
      #
      def default_sns_subject
        chef_client = Chef::Config[:solo] ? 'Chef Solo' : 'Chef Client'
        status = run_status.success? ? 'success' : 'failure'
        fix_subject_encoding("#{chef_client} #{status} in #{node.name}"[0..99])
      end

      #
      # Limits the size of a UTF-8 string in bytes without breaking it.
      #
      # Based on http://stackoverflow.com/questions/12536080/
      # ruby-limiting-a-utf-8-string-by-byte-length
      #
      # @param str [String] The string to limit.
      # @param size [Fixnum] The string size in bytes.
      #
      # @return [String] The final string.
      #
      # @note This code does not work properly on Ruby `< 2.1`.
      #
      # @api private
      #
      def limit_utf8_size(str, size)
        # Start with a string of the correct byte size, but with a possibly
        # incomplete char at the end.
        new_str = str.byteslice(0, size)

        # We need to force_encoding from utf-8 to utf-8 so ruby will
        # re-validate (idea from halfelf).
        until new_str[-1].force_encoding('utf-8').valid_encoding?
          # Remove the invalid char
          new_str = new_str.slice(0..-2)
        end
        new_str
      end

      #
      # Generates the SNS subject.
      #
      # @return [String] The subject string.
      #
      # @api private
      #
      def sns_subject
        return default_sns_subject unless subject
        context = self
        eruby = Erubis::Eruby.new(fix_subject_encoding(subject))
        fix_subject_encoding(eruby.evaluate(context))[0..99]
      end

      #
      # Generates the SNS body.
      #
      # @return [String] The body string.
      #
      # @api private
      #
      def sns_body
        template = IO.read(body_template ||
          "#{File.dirname(__FILE__)}/sns/templates/body.erb")
        context = self
        eruby = Erubis::Eruby.new(fix_body_encoding(template))
        body = fix_body_encoding(eruby.evaluate(context))
        limit_utf8_size(body, 262_144)
      end
    end
  end
end
