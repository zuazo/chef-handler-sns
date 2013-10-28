$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'simplecov'
if ENV['TRAVIS']
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
end
SimpleCov.start

gem 'minitest' # ensures you're using the gem, and not the built in MT
require 'minitest/autorun'
require 'mocha/setup'
require 'chef/handler/sns'
