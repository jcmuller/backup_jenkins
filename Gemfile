source :rubygems

# Specify your gem's dependencies in backup_jenkins.gemspec
gemspec

group :development do
  gem "guard"
  gem "guard-bundler"
  gem "guard-rspec"
  gem "rb-fchange", :require => false
  gem "rb-fsevent", :require => false
  gem "rb-inotify", :require => false
  gem "terminal-notifier-guard"
end

group :test do
  gem "ci_reporter"
  gem "fakeweb"
  gem "rake"
  gem "rspec"
  gem "simplecov"
  gem "simplecov-rcov"
end
