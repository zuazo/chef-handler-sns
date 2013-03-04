#
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2013 Onddo Labs, SL.
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
require 'right_aws'
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
        config_check
        sns.publish(topic_arn, sns_body, sns_subject)
      end
  
      protected

      def sns
        @sns ||= begin
          params = {
            :logger => Chef::Log
          }
          if (region)
            params[:region] = region
          elsif node.attribute?('ec2') and node.ec2.attribute?('placement_availability_zone')
            params[:region] = node.ec2.placement_availability_zone.chop
          end
          params[:token] = token if token
          RightAws::SnsInterface.new(access_key, secret_key, params)
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
