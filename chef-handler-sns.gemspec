$:.push File.expand_path("../lib", __FILE__)
require "chef/handler/sns/version"

Gem::Specification.new do |s|
  s.name = 'chef-handler-sns'
  s.version = ::Chef::Handler::Sns::VERSION
  s.date = '2013-03-02'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Chef SNS reports'
  s.description = 'Chef report handler to send SNS notifications on failures or changes'
  s.authors = ['Onddo Labs, SL.']
  s.email = 'team@onddo.com'
  s.homepage = 'http://github.com/onddo/chef-handler-sns'
  s.require_path = 'lib'
  s.files = %w(LICENSE README.md) + Dir.glob('lib/**/*')
  s.add_dependency 'right_aws', '~> 3.0'
end
