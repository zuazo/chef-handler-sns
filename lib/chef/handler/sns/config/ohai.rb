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

class Chef
  class Handler
    class Sns < ::Chef::Handler
      module Config
        # Gets Chef Handler SNS default configuration from
        # [Ohai](https://docs.chef.io/ohai.html) information.
        class Ohai
          # Not used, read from the topic ARN.
          attr_reader :region

          attr_reader :access_key

          attr_reader :secret_key

          attr_reader :token

          def initialize(node)
            read_config(node)
          end

          protected

          def read_region_config(ec2)
            return unless ec2.attribute?('placement_availability_zone') &&
                          ec2.placement_availability_zone.is_a?(String)
            @region = ec2.placement_availability_zone.chop
          end

          def read_iam_config(ec2)
            return unless ec2.attribute?('iam') &&
                          ec2.iam.attribute?('security-credentials')
            _iam_role, credentials = ec2.iam['security-credentials'].first
            return if credentials.nil?
            @access_key = credentials['AccessKeyId']
            @secret_key = credentials['SecretAccessKey']
            @token = credentials['Token']
          end

          def read_config(node)
            return unless node.attribute?('ec2')
            read_region_config(node.ec2)
            read_iam_config(node.ec2)
          end
        end
      end
    end
  end
end
