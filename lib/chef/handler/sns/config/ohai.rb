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

class Chef
  class Handler
    class Sns < ::Chef::Handler
      module Config
        class Ohai

          def initialize(node)
            read_config(node)
          end

          def region
            @region
          end

          def access_key
            @access_key
          end

          def secret_key
            @secret_key
          end

          def token
            @token
          end

          protected

          def read_config(node)
            return unless node.attribute?('ec2')
            if node.ec2.attribute?('placement_availability_zone') and
              node.ec2.placement_availability_zone.kind_of?(String)
              @region = node.ec2.placement_availability_zone.chop
            end
            if node.ec2.attribute?('iam') and node.ec2.iam.attribute?('security-credentials')
              iam_role, credentials = node.ec2.iam['security-credentials'].first
              unless credentials.nil?
                @access_key = credentials['AccessKeyId']
                @secret_key = credentials['SecretAccessKey']
                @token = credentials['Token']
              end
            end
          end

        end
      end
    end
  end
end
