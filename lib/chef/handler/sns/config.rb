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

require 'chef/handler/sns/config/ohai'
require 'chef/mixin/params_validate'
require 'chef/exceptions'

class Chef
  class Handler
    class Sns < ::Chef::Handler
      #
      # Reads Chef Handler SNS configuration options or calculate them if not
      # set.
      #
      module Config
        #
        # Let Config use the methods it contains as instance methods:
        #
        Config.extend Config

        #
        # Include `#set_or_return` code.
        #
        include ::Chef::Mixin::ParamsValidate

        #
        # Required configuration options.
        #
        REQUIRED = %w(access_key secret_key topic_arn)

        #
        # Reads some configuration options from Ohai information.
        #
        # Called from {.config_check}.
        #
        # @param node [Chef::Node] No objects to read the information from.
        #
        # @return void
        #
        # @api private
        #
        def config_from_ohai(node)
          config_ohai = Config::Ohai.new(node)
          [
            :access_key,
            :secret_key,
            :token
          ].each do |attr|
            send(attr, config_ohai.send(attr)) if send(attr).nil?
          end
        end

        #
        # Sets configuration reading it from a Hash.
        #
        # @param config [Hash] Configuration options to set.
        #
        # @return void
        #
        # @see Sns.initialize
        #
        # @api public
        #
        def config_init(config = {})
          config.each do |key, value|
            if Config.respond_to?(key) && !key.to_s.match(/^config_/)
              send(key, value)
            else
              Chef::Log.warn(
                "#{self.class}: configuration method not found: #{key}."
              )
            end
          end
        end

        #
        # Checks if any required configuration option is not set.
        #
        # Tries to read some configuration options from Ohai before checking
        # them.
        #
        # @param node [Chef::Node] Node to read Ohai information from.
        #
        # @return void
        #
        # @raise [Exceptions::ValidationFailed] When any required configuration
        #   option is not set.
        #
        # @api public
        #
        def config_check(node = nil)
          config_from_ohai(node) if node
          REQUIRED.each do |key|
            next unless send(key).nil?
            fail Exceptions::ValidationFailed,
                 "Required argument #{key} is missing!"
          end

          return unless body_template && !::File.exist?(body_template)
          fail Exceptions::ValidationFailed,
               "Template file not found: #{body_template}."
        end

        #
        # Gets or sets AWS access key.
        #
        # @param arg [String] Access key.
        #
        # @return [String] Access Key.
        #
        # @api public
        #
        def access_key(arg = nil)
          set_or_return(
            :access_key,
            arg,
            kind_of: String
          )
        end

        #
        # Gets or sets AWS secret key.
        #
        # @param arg [String] Secret key.
        #
        # @return [String] Secret Key.
        #
        # @api public
        #
        def secret_key(arg = nil)
          set_or_return(
            :secret_key,
            arg,
            kind_of: String
          )
        end

        #
        # Gets or sets AWS region.
        #
        # @param arg [String] Region.
        #
        # @return [String] Region.
        #
        # @api public
        #
        def region(arg = nil)
          set_or_return(
            :region,
            arg,
            kind_of: String
          )
        end

        #
        # Gets or sets AWS token.
        #
        # @param arg [String] Token.
        #
        # @return [String] Token.
        #
        # @api public
        #
        def token(arg = nil)
          set_or_return(
            :token,
            arg,
            kind_of: [String, FalseClass]
          )
        end

        #
        # Gets or sets AWS Topic ARN.
        #
        # It also tries to set the AWS region reading it from the ARN string.
        #
        # @param arg [String] Topic ARN.
        #
        # @return [String] Topic ARN.
        #
        # @api public
        #
        def topic_arn(arg = nil)
          set_or_return(
            :topic_arn,
            arg,
            kind_of: String
          ).tap do |arn|
            # Get the region from the ARN:
            next if arn.nil? || !region.nil?
            region(arn.split(':', 5)[3])
          end
        end

        #
        # Gets or sets SNS message subject.
        #
        # @param arg [String] SNS subject.
        #
        # @return [String] SNS subject.
        #
        # @api public
        #
        def subject(arg = nil)
          set_or_return(
            :subject,
            arg,
            kind_of: String
          )
        end

        #
        # Gets or sets SNS message body template file path.
        #
        # @param arg [String] SNS body template.
        #
        # @return [String] SNS body template.
        #
        # @api public
        #
        def body_template(arg = nil)
          set_or_return(
            :body_template,
            arg,
            kind_of: String
          )
        end

        #
        # Gets or sets [OpsWorks](https://aws.amazon.com/opsworks/) activities.
        #
        # Notifications will only be triggered for the activities in the array,
        # everything else will be discarded.
        #
        # @param arg [Array] Activities list.
        #
        # @return [Array] Activities list.
        #
        # @api public
        #
        def filter_opsworks_activity(arg = nil)
          arg = Array(arg) if arg.is_a? String
          set_or_return(
            :filter_opsworks_activity,
            arg,
            kind_of: Array
          )
        end
      end
    end
  end
end
