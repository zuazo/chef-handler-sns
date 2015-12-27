#!/usr/bin/env rake
# encoding: utf-8
require 'bundler'
Bundler::GemHelper.install_tasks

desc 'Clean some generated files'
task :clean do
  %w(
    .bundle
    .cache
    coverage
    doc
    *.gem
    Gemfile.lock
    .inch
    vendor
    .yardoc
  ).each { |f| FileUtils.rm_rf(Dir.glob(f)) }
end

desc 'Generate Ruby documentation'
task :yard do
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.stats_options = %w(--list-undoc)
  end
end

task doc: %w(yard)

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
