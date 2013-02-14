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
require 'chef/resource/directory'

require 'right_aws'

class Chef
  class Handler
    class Sns < ::Chef::Handler
      attr_writer :access_key, :secret_key, :region, :token, :topic_arn
  
      def initialize(config={})
        Chef::Log.debug("#{self.class.to_s} initialized.")
        @access_key = config[:access_key]
        @secret_key = config[:secret_key]
        @region = config[:region] if config.has_key?(:region)
        @token = config[:token] if config.has_key?(:token)
        @topic_arn = config[:topic_arn]
      end
  
      def report
        check_config
        Chef::Log.debug("#{self.class.to_s} reporting.")
        sns.publish(@topic_arn, sns_body, sns_subject)
      end
  
      protected
  
      def check_config
        Chef::Log.debug("#{self.class.to_s} checking handler configuration.")
        raise "access_key not properly set" unless @access_key.kind_of?(String)
        raise "secret_key not properly set" unless @secret_key.kind_of?(String)
        raise "region not properly set" unless @region.kind_of?(String) or @region.nil?
        raise "topic_arn not properly set" unless @topic_arn.kind_of?(String)
        raise "token not properly set" unless @token.kind_of?(String) or @token.nil?
      end

      def sns
        params = {
          :logger => Chef::Log,
          :region => @region || node.ec2.placement_availability_zone.chop
        }
        params[:token] = @token if @token
        @sns ||= RightAws::SnsInterface.new(@access_key, @secret_key, params)
      end
  
      def sns_subject
        chef_client = Chef::Config[:solo] ? 'Chef Solo' : 'Chef Client'
        status = run_status.success? ? 'success' : 'failure'
        "#{chef_client} #{status} in #{node.name}"
      end
  
      def sns_body
        message = ''
  
        message << "Node Name: #{node.name}\n"
        message << "Hostname: #{node.fqdn}\n"
        message << "\n"

        message << "Chef Run List: #{node.run_list.to_s}\n"
        message << "Chef Environment: #{node.chef_environment}\n"
        message << "\n"

        if node.attribute?('ec2')
          message << "Instance Id: #{node.ec2.instance_id}\n"
          message << "Instance Public Hostname: #{node.ec2.public_hostname}\n"
          message << "Instance Hostname: #{node.ec2.hostname}\n"
          message << "Instance Public IPv4: #{node.ec2.public_ipv4}\n"
          message << "Instance Local IPv4: #{node.ec2.local_ipv4}\n"
        end
        message << "\n"
  
        message << "Chef Client Elapsed Time: #{elapsed_time.to_s}\n"
        message << "Chef Client Start Time: #{start_time.to_s}\n"
        message << "Chef Client Start Time: #{end_time.to_s}\n"
        message << "\n"
  
        if exception
          message << "Exception: #{run_status.formatted_exception}\n"
          message << "Stacktrace:\n"
          message << Array(backtrace).join("\n")
          message << "\n"
        end
      end
  
    end
  end
end
