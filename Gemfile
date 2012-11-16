source :rubygems

# Specify your gem's dependencies in backup_jenkins.gemspec
gemspec

group :development do
  gem "rb-fchange", :require => false
  gem "rb-fsevent", :require => false
  gem "rb-inotify", :require => false
end

group :test do
  gem "ci_reporter"
  gem "fakeweb"
  gem "rake"
  gem "rspec"
  gem "simplecov"
  gem "simplecov-rcov"
end
