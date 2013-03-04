require 'helper'
require 'chef/node'
require 'chef/run_status'

class RightAws::FakeSnsInterface < RightAws::SnsInterface
  attr_reader :sns_interface_new, :topic_arn, :message, :subject

  def fake_new
    @sns_interface_new = true
    return self
  end

end

class Chef::Handler::FakeSns < Chef::Handler::Sns

  def get_sns_subject
    sns_subject
  end

  def get_sns_body
    sns_body
  end

end

describe Chef::Handler::Sns do
  before do
    RightAws::SnsInterface.any_instance.stubs(:publish).returns(true)

    @node = Chef::Node.new
    @node.name('test')
    Chef::Handler::Sns.any_instance.stubs(:node).returns(@node)

    @run_status = Chef::RunStatus.new(@node, {})
    @run_status.start_clock
    @run_status.stop_clock

    @config = {
      :access_key => '***AMAZON-KEY***',
      :secret_key => '***AMAZON-SECRET***',
      :topic_arn => 'arn:aws:sns:***',
    }
  end

  it 'should read the configuration options on initialization' do
    @sns_handler = Chef::Handler::Sns.new(@config)
    assert_equal @sns_handler.access_key, @config[:access_key]
    assert_equal @sns_handler.secret_key, @config[:secret_key]
  end

  it 'should be able to change configuration options using method calls' do
    @sns_handler = Chef::Handler::Sns.new
    @sns_handler.access_key(@config[:access_key])
    @sns_handler.secret_key(@config[:secret_key])
    assert_equal @sns_handler.access_key, @config[:access_key]
    assert_equal @sns_handler.secret_key, @config[:secret_key]
  end

  it 'should try to send a SNS message when properly configured' do
    @sns_handler = Chef::Handler::Sns.new(@config)
    RightAws::SnsInterface.any_instance.expects(:publish).once

    @sns_handler.run_report_safely(@run_status)
  end

  it 'should create a RightAws::SnsInterface object' do
    @sns_handler = Chef::Handler::Sns.new(@config)
    fake_sns = RightAws::FakeSnsInterface.new(@config[:access_key], @config[:secret_key], {:logger => Chef::Log})
    RightAws::SnsInterface.any_instance.stubs(:new).returns(fake_sns.fake_new)
    @sns_handler.run_report_safely(@run_status)

    assert_equal fake_sns.sns_interface_new, true
  end

  it 'should detect the AWS region automatically' do
    @node.set['ec2']['placement_availability_zone'] = 'eu-west-1a'
    @sns_handler = Chef::Handler::Sns.new(@config)
    @sns_handler.run_report_safely(@run_status)

    @sns_handler.server.must_match Regexp.new('eu-west-1')
  end

  it 'should not detect AWS region automatically whan manually set' do
    @node.set['ec2']['placement_availability_zone'] = 'eu-west-1a'
    @config[:region] = 'us-east-1'
    @sns_handler = Chef::Handler::Sns.new(@config)
    @sns_handler.run_report_safely(@run_status)

    @sns_handler.server.must_match Regexp.new('us-east-1')
  end

  it 'should be able to generate the default subject in chef-client' do
    Chef::Config[:solo] = false
    @fake_sns_handler = Chef::Handler::FakeSns.new(@config)
    Chef::Handler::FakeSns.any_instance.stubs(:node).returns(@node)
    @fake_sns_handler.run_report_unsafe(@run_status)

    assert_equal @fake_sns_handler.get_sns_subject, 'Chef Client success in test'
  end

  it 'should be able to generate the default subject in chef-solo' do
    Chef::Config[:solo] = true
    @fake_sns_handler = Chef::Handler::FakeSns.new(@config)
    Chef::Handler::FakeSns.any_instance.stubs(:node).returns(@node)
    @fake_sns_handler.run_report_unsafe(@run_status)

    assert_equal @fake_sns_handler.get_sns_subject, 'Chef Solo success in test'
  end

  it 'should use the configured subject when set' do
    @config[:subject] = 'My Subject'
    @fake_sns_handler = Chef::Handler::FakeSns.new(@config)
    Chef::Handler::FakeSns.any_instance.stubs(:node).returns(@node)
    @fake_sns_handler.run_report_unsafe(@run_status)

    assert_equal @fake_sns_handler.get_sns_subject, 'My Subject'
  end

end
