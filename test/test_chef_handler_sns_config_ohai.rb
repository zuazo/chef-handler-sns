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

require 'helper'

# rubocop:disable Metrics/BlockLength
describe Chef::Handler::Sns::Config::Ohai do
  let(:node) do
    Chef::Node.new.tap do |node|
      node.name('test')
      node.override['ec2'] = {
        'placement_availability_zone' => 'region1a',
        'iam' => {
          'security-credentials' => {
            'iam-role1' => {
              'AccessKeyId' => 'access_key1',
              'SecretAccessKey' => 'secret_key1',
              'Token' => 'token1'
            }
          }
        }
      }
    end
  end
  let(:config) { Chef::Handler::Sns::Config::Ohai.new(node) }
  let(:node_override_iam_roles) do
    node.override['ec2']['iam']['security-credentials']
  end

  describe 'read_config' do
    it 'reads the region' do
      assert_equal 'region1', config.region
    end

    it 'does not read the region when not set' do
      node.override['ec2']['placement_availability_zone'] = nil
      assert_nil config.region
    end

    it 'does not read the credentials when has not IAM role' do
      node.override['ec2'] = {}
      assert_nil config.access_key
    end

    it 'reads the access_key' do
      assert_equal 'access_key1', config.access_key
    end

    it 'does not read the access_key when not set' do
      node_override_iam_roles['iam-role1']['AccessKeyId'] = nil
      assert_nil config.access_key
    end

    it 'reads the secret_key' do
      assert_equal 'secret_key1', config.secret_key
    end

    it 'does not read the secret_key when not set' do
      node_override_iam_roles['iam-role1']['SecretAccessKey'] = nil
      assert_nil config.secret_key
    end

    it 'reads the security token' do
      assert_equal 'token1', config.token
    end

    it 'does not read the security token when not set' do
      node_override_iam_roles['iam-role1']['Token'] = nil
      assert_nil config.token
    end
  end
end
# rubocop:enable Metrics/BlockLength
