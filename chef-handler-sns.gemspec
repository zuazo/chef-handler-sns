$:.push File.expand_path("../lib", __FILE__)
require "chef/handler/sns/version"
chef_version = ENV.key?('CHEF_VERSION') ? "#{ENV['CHEF_VERSION']}" : ['>= 0.9.0']

Gem::Specification.new do |s|
  s.name = 'chef-handler-sns'
  s.version = ::Chef::Handler::Sns::VERSION
  s.date = '2014-07-04'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Chef SNS reports'
  s.description = 'Chef report handler to send Amazon SNS notifications on failures or changes, includes IAM roles support'
  s.license = 'Apache-2.0'
  s.authors = ['Onddo Labs, SL.']
  s.email = 'team@onddo.com'
  s.homepage = 'http://onddo.github.io/chef-handler-sns'
  s.require_path = 'lib'
  s.files = %w(LICENSE README.md) + Dir.glob('lib/**/*')
  s.test_files = Dir.glob('{test,spec,features}/*')

  s.add_dependency 'aws-sdk', '~> 1.0'
  s.add_dependency 'erubis', '~> 2.0'

  if RUBY_VERSION < '1.9'
    s.add_development_dependency 'mime-types', '< 2.0'
    s.add_development_dependency 'nokogiri', '< 1.6.0'
    s.add_development_dependency 'moneta', '< 0.8'
  end
  if RUBY_VERSION < '1.9.3'
    s.add_development_dependency 'mixlib-shellout', '< 1.6.1'
  end
  if RUBY_VERSION < '2'
    s.add_development_dependency 'highline', '< 1.7'
    s.add_development_dependency 'ohai', '< 8'
    s.add_development_dependency 'amq-protocol', '< 2'
    s.add_development_dependency 'bunny', '< 2'
  end
  s.add_development_dependency 'chef', chef_version
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'minitest', '~> 5.7'
  s.add_development_dependency 'mocha', '~> 1.1'
  s.add_development_dependency 'coveralls', '~> 0.7'
  s.add_development_dependency 'simplecov', '~> 0.9'
end
