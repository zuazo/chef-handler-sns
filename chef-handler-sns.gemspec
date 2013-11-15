$:.push File.expand_path("../lib", __FILE__)
require "chef/handler/sns/version"
chef_version = ENV.key?('CHEF_VERSION') ? "#{ENV['CHEF_VERSION']}" : ['>= 0.9.0']

Gem::Specification.new do |s|
  s.name = 'chef-handler-sns'
  s.version = ::Chef::Handler::Sns::VERSION
  s.date = '2013-03-17'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Chef SNS reports'
  s.description = 'Chef report handler to send SNS notifications on failures or changes'
  s.license = 'Apache-2.0'
  s.authors = ['Onddo Labs, SL.']
  s.email = 'team@onddo.com'
  s.homepage = 'http://onddo.github.io/chef-handler-sns'
  s.require_path = 'lib'
  s.files = %w(LICENSE README.md) + Dir.glob('lib/**/*')
  s.test_files = Dir.glob('{test,spec,features}/*')

  s.add_dependency 'right_aws', '~> 3.0'
  s.add_dependency 'erubis'

  s.add_development_dependency 'mime-types', '~> 1.0' # 2.0 requires Ruby 1.9
  s.add_development_dependency 'chef', chef_version
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'simplecov'
end
