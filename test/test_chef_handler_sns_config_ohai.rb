require 'helper'

describe Chef::Handler::Sns::Config::Ohai do
  before do
    @node = Chef::Node.new
    @node.name('test')
    @node.set['ec2'] = {
      'placement_availability_zone' => 'region1a',
      'iam' => {
        'security-credentials' => {
          'iam-role1' => {
            'AccessKeyId' => 'access_key1',
            'SecretAccessKey' => 'secret_key1',
            'Token' => 'token1',
          }
        }
      }
    }
  end

  describe 'read_config' do

    it 'should read the region' do
      config = Chef::Handler::Sns::Config::Ohai.new(@node)
      assert_equal config.region, 'region1'
    end

    it 'should not read the region when not set' do
      @node.set['ec2']['placement_availability_zone'] = nil
      config = Chef::Handler::Sns::Config::Ohai.new(@node)
      assert_equal config.region, nil
    end

    it 'should not read the credentials when has not IAM role' do
      @node.set['ec2'] = {}
      config = Chef::Handler::Sns::Config::Ohai.new(@node)
      assert_equal config.access_key, nil
    end

    it 'should read the access_key' do
      config = Chef::Handler::Sns::Config::Ohai.new(@node)
      assert_equal config.access_key, 'access_key1'
    end

    it 'should not read the access_key when not set' do
      @node.set['ec2']['iam']['security-credentials']['iam-role1']['AccessKeyId'] = nil
      config = Chef::Handler::Sns::Config::Ohai.new(@node)
      assert_equal config.access_key, nil
    end

    it 'should read the secret_key' do
      config = Chef::Handler::Sns::Config::Ohai.new(@node)
      assert_equal config.secret_key, 'secret_key1'
    end

    it 'should not read the secret_key when not set' do
      @node.set['ec2']['iam']['security-credentials']['iam-role1']['SecretAccessKey'] = nil
      config = Chef::Handler::Sns::Config::Ohai.new(@node)
      assert_equal config.secret_key, nil
    end

    it 'should read the security token' do
      config = Chef::Handler::Sns::Config::Ohai.new(@node)
      assert_equal config.token, 'token1'
    end

    it 'should not read the security token when not set' do
      @node.set['ec2']['iam']['security-credentials']['iam-role1']['Token'] = nil
      config = Chef::Handler::Sns::Config::Ohai.new(@node)
      assert_equal config.token, nil
    end

  end

end
