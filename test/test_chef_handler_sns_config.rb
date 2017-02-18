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
require 'chef/exceptions'

class SnsConfig
  include Chef::Handler::Sns::Config
end

class ChefFakeOhai < Chef::Handler::Sns::Config::Ohai
  def intialize; end
end

# rubocop:disable Metrics/BlockLength
describe Chef::Handler::Sns::Config do
  let(:node) do
    node = Chef::Node.new
    node.name('test')
    node
  end
  let(:sns_config) { SnsConfig.new }
  let(:config_params) do
    {
      access_key: '***AMAZON-KEY***',
      secret_key: '***AMAZON-SECRET***',
      token: '***AMAZON-TOKEN***',
      topic_arn: 'arn:aws:sns:***'
    }
  end

  it 'reads the configuration options on config initialization' do
    sns_config.config_init(config_params)

    assert_equal config_params[:access_key], sns_config.access_key
    assert_equal config_params[:secret_key], sns_config.secret_key
  end

  it 'is able to change configuration options using method calls' do
    sns_config.access_key(config_params[:access_key])
    sns_config.secret_key(config_params[:secret_key])

    assert_equal config_params[:access_key], sns_config.access_key
    assert_equal config_params[:secret_key], sns_config.secret_key
  end

  [:access_key, :secret_key, :topic_arn].each do |required|
    it "throws an exception when '#{required}' required field is not set" do
      config_params.delete(required)
      config_params.each { |key, value| sns_config.send(key, value) }

      assert_raises(Chef::Exceptions::ValidationFailed) do
        sns_config.config_check
      end
    end
  end

  [
    :access_key, :secret_key, :region, :token, :topic_arn, :message_structure
  ].each do |option|
    it "accepts string values in '#{option}' option" do
      sns_config.send(option, 'test')
    end

    it "sets '#{option}' option correctly" do
      sns_config.send(option, 'test')

      assert_equal 'test', sns_config.send(option)
    end

    [true, 25, Object.new].each do |bad_value|
      it "throws and exception wen '#{option}' option is set to #{bad_value}" do
        assert_raises(Chef::Exceptions::ValidationFailed) do
          sns_config.send(option, bad_value)
        end
      end
    end
  end

  it 'accepts false value to reset the token' do
    sns_config.token(false)
    assert_equal false, sns_config.token
  end

  it 'throws an exception when the body template file does not exist' do
    sns_config.body_template('/tmp/nonexistent-template.erb')
    ::File.stubs(:exist?).with(sns_config.body_template).returns(false)

    assert_raises(Chef::Exceptions::ValidationFailed) do
      sns_config.config_check
    end
  end

  describe 'config_init' do
    it 'accepts valid config options' do
      option = :access_key
      Chef::Log.expects(:warn).never

      sns_config.config_init(option => 'valid')
    end

    it 'does not accept invalid config options' do
      option = :invalid_option
      assert !sns_config.respond_to?(option)
      Chef::Log.expects(:warn).once

      sns_config.config_init(option => 'none')
    end

    it 'does not accept config options starting by "config_"' do
      option = :config_check
      assert sns_config.respond_to?(option)
      Chef::Log.expects(:warn).once

      sns_config.config_init(option => 'exists but not configurable')
    end
  end

  describe 'config_check' do
    it 'calls #config_from_ohai method' do
      sns_config.access_key(config_params[:access_key])
      sns_config.secret_key(config_params[:secret_key])
      sns_config.topic_arn(config_params[:topic_arn])
      sns_config.expects(:config_from_ohai).once

      sns_config.config_check(node)
    end
  end

  describe 'config_from_ohai' do
    before do
      @fake_ohai = ChefFakeOhai.new(node)
      Chef::Handler::Sns::Config::Ohai.stubs(:new).returns(@fake_ohai)
    end

    it 'creates Config::Ohai object' do
      Chef::Handler::Sns::Config::Ohai.expects(:new).once.returns(@fake_ohai)

      sns_config.config_from_ohai(node)
    end

    [
      :access_key,
      :secret_key,
      :token
    ].each do |method|
      it "calls Config::Ohai##{method} method" do
        @fake_ohai.expects(method).once

        sns_config.config_from_ohai(node)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
