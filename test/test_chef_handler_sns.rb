require 'helper'
require 'chef/node'
require 'chef/run_status'

describe Chef::Handler::Sns do
  before do
    RightAws::SnsInterface.any_instance.stubs(:publish).returns(true)

    @node = Chef::Node.new
    @node.name('test')
    Chef::Handler::Sns.any_instance.stubs(:node).returns(@node)

    @run_status = Chef::RunStatus.new(@node, {})
    @run_status.start_clock
    @run_status.stop_clock
  end

  it 'sends a SNS message when properly configured' do
    @sns_handler = Chef::Handler::Sns.new

    @sns_handler.access_key('***AMAZON-KEY***')
    @sns_handler.secret_key('***AMAZON-SECRET***')
    @sns_handler.topic_arn('arn:aws:sns:***')
    RightAws::SnsInterface.any_instance.expects(:publish).once

    @sns_handler.run_report_safely(@run_status)
  end

end
