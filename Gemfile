source :rubygems

# Specify your gem's dependencies in backup_jenkins.gemspec
gemspec

group :development do
  gem "guard"
  gem "guard-rspec"
  gem "guard-bundler"
  gem "rb-inotify", require: false
  gem "rb-fsevent", require: false
  gem "rb-fchange", require: false
  gem "terminal-notifier-guard"
end

group :test do
  gem "rake"
  gem "rspec"
  gem "ci_reporter"
  gem "simplecov"
  gem "simplecov-rcov"
  gem "flog"
end
