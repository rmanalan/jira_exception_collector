source 'http://rubygems.org'

# Specify your gem's dependencies in jira_notifier.gemspec
gemspec

group :test do
  gem 'rake'
  gem 'test-unit'
  gem 'fakeweb'
  gem 'bundler', '>= 1.0.0'
  gem 'rack'
  if RUBY_VERSION =~ /^1\.9/
    gem 'ruby-debug19'
  else
    gem 'ruby-debug'
  end
end

