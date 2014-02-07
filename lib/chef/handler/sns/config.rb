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

require 'chef/mixin/params_validate'
require 'chef/exceptions'

class Chef
  class Handler
    class Sns < ::Chef::Handler
      module Config
        Config.extend Config # let Config use the methods it contains as instance methods
        include ::Chef::Mixin::ParamsValidate

        REQUIRED = [ 'access_key', 'secret_key', 'topic_arn' ]

        def config_from_ohai(node)
          if node.attribute?('ec2')
            if region.nil? and node.ec2.attribute?('placement_availability_zone')
              region(node.ec2.placement_availability_zone.chop)
            end
            if node.ec2.attribute?('iam') and node.ec2.iam.attribute?('security-credentials')
              iam_role, credentials = node.ec2.iam['security-credentials'].first
              unless credentials.nil?
                access_key(credentials['AccessKeyId']) if access_key.nil?
                secret_key(credentials['SecretAccessKey']) if secret_key.nil?
                token(credentials['Token']) if token.nil?
              end
            end
          end
        end

        def config_init(config={})
          config.each do |key, value|
            if Config.respond_to?(key) and not /^config_/ =~ key.to_s
              self.send(key, value)
            else
              Chef::Log.warn("#{self.class.to_s}: configuration method not found: #{key}.")
            end
          end
        end

        def config_check(node=nil)
          config_from_ohai(node) if node
          REQUIRED.each do |key|
            if self.send(key).nil?
              raise Exceptions::ValidationFailed,
                "Required argument #{key.to_s} is missing!"
            end
          end

          if body_template and not ::File.exists?(body_template)
            raise Exceptions::ValidationFailed,
              "Template file not found: #{body_template}."
          end
        end

        def access_key(arg=nil)
          set_or_return(
            :access_key,
            arg,
            :kind_of => String
          )
        end

        def secret_key(arg=nil)
          set_or_return(
            :secret_key,
            arg,
            :kind_of => String
          )
        end

        def region(arg=nil)
          set_or_return(
            :region,
            arg,
            :kind_of => String
          )
        end

        def token(arg=nil)
          set_or_return(
            :token,
            arg,
            :kind_of => String
          )
        end

        def topic_arn(arg=nil)
          set_or_return(
            :topic_arn,
            arg,
            :kind_of => String
          )
        end

        def subject(arg=nil)
          set_or_return(
            :subject,
            arg,
            :kind_of => String
          )
        end

        def body_template(arg=nil)
          set_or_return(
            :body_template,
            arg,
            :kind_of => String
          )
        end

      end
    end
  end
end
