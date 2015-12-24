#!/usr/bin/env rake
# encoding: utf-8
require 'bundler'
Bundler::GemHelper.install_tasks

desc 'Run RuboCop style checks'
task :rubocop do
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end

desc 'Run all style checks'
task style: %w(rubocop)

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task default: %w(style test)
