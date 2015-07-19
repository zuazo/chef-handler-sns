#
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
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
          sns.topics[topic_arn].publish(
            sns_body.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'}),
            { :subject => sns_subject }
          )
        end
      end

      def get_region
        sns.config.region
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
          AWS::SNS.new(params)
        end
      end

      def sns_subject
        if subject
          context = self
          eruby = Erubis::Eruby.new(subject)
          eruby.evaluate(context)
        else
          chef_client = Chef::Config[:solo] ? 'Chef Solo' : 'Chef Client'
          status = run_status.success? ? 'success' : 'failure'
          "#{chef_client} #{status} in #{node.name}"
        end
      end

      def sns_body
        template = IO.read(body_template || "#{File.dirname(__FILE__)}/sns/templates/body.erb")
        context = self
        eruby = Erubis::Eruby.new(template)
        eruby.evaluate(context)
      end

    end
  end
end
