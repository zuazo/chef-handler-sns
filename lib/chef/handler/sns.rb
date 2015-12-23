#
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
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
  class Handler
    class Sns < ::Chef::Handler
      include ::Chef::Handler::Sns::Config

      def initialize(config={})
        Chef::Log.debug("#{self.class.to_s} initialized.")
        config_init(config)
      end

      def report
        config_check(node)
        if allow_publish(node)
          sns.publish(
            topic_arn: topic_arn,
            message: sns_body,
            subject: sns_subject
          )
        end
      end

      protected

      def allow_publish(node)
        if filter_opsworks_activity.nil?
          return true
        end

        if node.attribute?('opsworks') && node['opsworks'].attribute?('activity')
          return filter_opsworks_activity.include?(node['opsworks']['activity'])
        end

        Chef::Log.debug('You supplied opsworks activity filters, but node attr was not found. Returning false')
        return false
      end

      def sns
        @sns ||= begin
          params = {
            :access_key_id => access_key,
            :secret_access_key => secret_key,
            :logger => Chef::Log
          }
          params[:region] = region if region
          params[:session_token] = token if token
          Aws::SNS::Client.new(params)
        end
      end

      def fix_encoding(o, encoding)
        o.to_s.encode(
          encoding, 'binary', invalid: :replace, undef: :replace, replace: '?'
        )
      end

      def fix_subject_encoding(o)
        fix_encoding(o, 'ASCII')
      end

      def fix_body_encoding(o)
        fix_encoding(o, 'UTF-8')
      end

      def default_sns_subject
        chef_client = Chef::Config[:solo] ? 'Chef Solo' : 'Chef Client'
        status = run_status.success? ? 'success' : 'failure'
        fix_subject_encoding("#{chef_client} #{status} in #{node.name}"[0..99])
      end

      def sns_subject
        return default_sns_subject unless subject
        context = self
        eruby = Erubis::Eruby.new(fix_subject_encoding(subject))
        fix_subject_encoding(eruby.evaluate(context))[0..99]
      end

      def sns_body
        template = IO.read(body_template || "#{File.dirname(__FILE__)}/sns/templates/body.erb")
        context = self
        eruby = Erubis::Eruby.new(fix_body_encoding(template))
        fix_body_encoding(eruby.evaluate(context))
      end

    end
  end
end
