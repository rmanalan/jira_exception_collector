# JIRA Exception Collector

[![Travis CI](https://secure.travis-ci.org/manalang/jira_exception_collector.png?branch=master)](http://travis-ci.org/manalang/jira_exception_collector)

A gem that logs your exceptions as a JIRA issue. Once it's in JIRA, you can route it to
the appropriate developer to fix the issue using JIRA's workflow engine.

![Moneyshot](https://img.skitch.com/20111201-dwre1a5ic7p1xk51pye9y483xh.png)

## Installation

JIRA Exception Collector is a gem. To install:

    gem install jira_exception_collector

... or, add this to your Gemfile:

    gem jira_exception_collector

... then:

    bundle install

## Usage

This gem utilizes the [JIRA Issue Collector plugin](https://plugins.atlassian.com/583856).
Make sure your JIRA instance has this plugin installed before using this gem.

## Setup an Issue Collector in JIRA

In JIRA, go to Administration > Issue Collectors. You'll need to be a JIRA administrator
to do this. Add a new Issue Collector pointing to the project you want the exceptions to
go to. Also, if you don't already have an Issue Type for exceptions, you might want to
create one so that you have a better way of organizing the issues in your project.

Once you create the Issue Collector, copy the Collector URL (found on the Issue Collector's
page).

## Configure your Rack app with the Collector URL

This gem works with any Rack based app. To configure it, first crack open your config.ru
and add this before the `run` statement:

````ruby
use Rack::JiraExceptionCollector, "https://collector_url"
````

By default, JIRA Exception Collector is enabled under production and staging environments.
To modify this, just supply an array of the environments you want exceptions to be logged
inside the block syntax:

````ruby
use Rack::JiraExceptionCollector, "https://collector_url" do |collector|
  collector.report_under << "your_custom_env"
end
````

You can also configure filters to scrub out sensitive environment variables:

````ruby
use Rack::JiraExceptionCollector do |collector|
  collector.collector_url = "https://collector_url"
  collector.report_under << "your_custom_env"
  collector.environment_filters << %w(SECRET_KEY SECRET_TOKEN)
end
````

## Compatibility with JIRA

Because this gem relies on the [JIRA Issue Collector plugin](https://plugins.atlassian.com/583856),
this gem is only compatible with the JIRA versions that the JIRA Issue Collector supports.

## Contributing

This is a [pushmepullyou](http://amysuenathan.com/wp-content/uploads/2009/03/pushmepullyou.jpg) 
type of project. Fork it hard, push in your awesome sauce, then send in your pull request. Oh, 
don't forget to add tests.

## Copyright

Copyright (c) Rich Manalang and Atlassian, Inc. See LICENSE for details.
