require 'helper'
require 'chef/exceptions'

class SnsConfig
  include Chef::Handler::Sns::Config
end

describe Chef::Handler::Sns::Config do
  before do
    @config_params = {
      :access_key => '***AMAZON-KEY***',
      :secret_key => '***AMAZON-SECRET***',
      :topic_arn => 'arn:aws:sns:***',
    }
    @sns_config = SnsConfig.new
  end

  it 'should read the configuration options on config initialization' do
    @sns_config.config_init(@config_params)

    assert_equal @sns_config.access_key, @config_params[:access_key]
    assert_equal @sns_config.secret_key, @config_params[:secret_key]
  end

  it 'should be able to change configuration options using method calls' do
    @sns_config.access_key(@config_params[:access_key])
    @sns_config.secret_key(@config_params[:secret_key])

    assert_equal @sns_config.access_key, @config_params[:access_key]
    assert_equal @sns_config.secret_key, @config_params[:secret_key]
  end

  [ :access_key, :secret_key, :topic_arn ].each do |required|
    it "should throw an exception when '#{required}' required field is not set" do
      @config_params.delete(required)
      @config_params.each { |key, value| @sns_config.send(key, value) }

      assert_raises(Chef::Exceptions::ValidationFailed) { @sns_config.config_check }
    end
  end

  [ :access_key, :secret_key, :region, :token, :topic_arn ].each do |option|

    it "should accept string values in '#{option}' option" do
      @sns_config.send(option, "test")
    end

    [ true, false, 25, Object.new ].each do |bad_value|
      it "should throw and exception wen '#{option}' option is set to #{bad_value.to_s}" do
        assert_raises(Chef::Exceptions::ValidationFailed) { @sns_config.send(option, bad_value) }
      end
    end
  end

  it 'should throw an exception when the body template file does not exist' do
    @sns_config.body_template('/tmp/nonexistent-template.erb')
    ::File.stubs(:exists?).with(@sns_config.body_template).returns(false)

    assert_raises(Chef::Exceptions::ValidationFailed) { @sns_config.config_check }
  end


end
