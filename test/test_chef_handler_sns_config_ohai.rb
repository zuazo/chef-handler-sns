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
