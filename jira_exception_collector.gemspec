# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack/jira_exception_collector_version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "jira_exception_collector"
  gem.authors       = ["Rich Manalang"]
  gem.email         = ["rmanalang@atlassian.com"]
  gem.description   = %q{A basic exception logger that logs to a JIRA instance}
  gem.summary       = %q{jira_notifier will log your exceptions to a JIRA instance}
  gem.homepage      = "https://github.com/manalang/jira_exception_collector"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]
  gem.version       = Rack::JiraExceptionCollector::VERSION
  gem.add_dependency 'rack'
  gem.extra_rdoc_files = ['README.md','LICENSE']

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'test-unit'
  gem.add_development_dependency 'fakeweb'
end
