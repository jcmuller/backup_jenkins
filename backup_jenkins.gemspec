# -*- encoding: utf-8 -*-
require File.expand_path('../lib/backup_jenkins/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Juan C. Müller"]
  gem.email         = ["jcmuller@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = Dir["spec/**/*_spec.rb"]
  gem.name          = "backup_jenkins"
  gem.require_paths = ["lib"]
  gem.version       = BackupJenkins::VERSION

  gem.add_dependency("aws-sdk")

  gem.add_development_dependency("rake")
  gem.add_development_dependency("pry-debugger")
  gem.add_development_dependency("pry-stack_explorer")
end
