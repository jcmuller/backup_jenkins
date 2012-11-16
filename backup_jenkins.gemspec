# -*- encoding: utf-8 -*-
require File.expand_path('../lib/backup_jenkins/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Juan C. Müller"]
  gem.email         = ["jcmuller@gmail.com"]
  gem.description   = %{Simple Jenkins config and plugin backup to S3}
  gem.summary       = %q{This gem allows you to get a backup instance of jenkins up and running pretty quickly}
  gem.homepage      = "http://github.com/jcmuller/backup_jenkins"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = Dir["spec/**/*_spec.rb"]
  gem.name          = "backup_jenkins"
  gem.require_paths = ["lib"]
  gem.version       = BackupJenkins::VERSION

  gem.add_dependency("aws-sdk")
  gem.add_dependency("hashie")
  gem.add_dependency("command_line_helper")

  gem.add_development_dependency("rake")
  gem.add_development_dependency("guard")
  gem.add_development_dependency("guard-bundler")
  gem.add_development_dependency("guard-rspec")
  gem.add_development_dependency("terminal-notifier-guard")
end
