require 'rubygems'
require 'bundler/setup'
Bundler.require(:test)
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'rack/mock'
require 'rack/lobster'
require 'rack/jira_exception_collector'
