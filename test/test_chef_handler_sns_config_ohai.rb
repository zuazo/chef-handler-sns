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

describe Chef::Handler::Sns::Config::Ohai do
  let(:node) do
    node = Chef::Node.new
    node.name('test')
    node.set['ec2'] = {
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
    node
  end
  let(:config) { Chef::Handler::Sns::Config::Ohai.new(node) }
  let(:node_set_iam_roles) { node.set['ec2']['iam']['security-credentials'] }

  describe 'read_config' do
    it 'reads the region' do
      assert_equal 'region1', config.region
    end

    it 'does not read the region when not set' do
      node.set['ec2']['placement_availability_zone'] = nil
      assert_equal nil, config.region
    end

    it 'does not read the credentials when has not IAM role' do
      node.set['ec2'] = {}
      assert_equal nil, config.access_key
    end

    it 'reads the access_key' do
      assert_equal 'access_key1', config.access_key
    end

    it 'does not read the access_key when not set' do
      node_set_iam_roles['iam-role1']['AccessKeyId'] = nil
      assert_equal nil, config.access_key
    end

    it 'reads the secret_key' do
      assert_equal 'secret_key1', config.secret_key
    end

    it 'does not read the secret_key when not set' do
      node_set_iam_roles['iam-role1']['SecretAccessKey'] = nil
      assert_equal nil, config.secret_key
    end

    it 'reads the security token' do
      assert_equal 'token1', config.token
    end

    it 'does not read the security token when not set' do
      node_set_iam_roles['iam-role1']['Token'] = nil
      assert_equal nil, config.token
    end
  end
end
