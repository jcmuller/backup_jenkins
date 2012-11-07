#!/usr/bin/env rake
$:.push File.expand_path("../lib", __FILE__)

require "rspec/core/rake_task"
require "backup_jenkins/version"
require "bundler/gem_tasks"

#RSpec::Core::RakeTask.new(:spec) do |spec|
#  spec.pattern = "spec/**/*_spec.rb"
#  spec.rspec_opts = ["--backtrace --format CI::Reporter::RSpec"]
#end

desc "Clean backup and swap files, and artifacts"
task :clean do
  require "fileutils"
  Dir["{pkg/*,**/*~,**/.*.sw?,coverage/**,spec/reports/**}"].each do |file|
    rm_rf file
  end
end

desc "Run rspec by default"
task :default => :spec
