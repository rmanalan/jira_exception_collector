# JIRA Exception Collector

A gem that logs your exceptions as a JIRA issue. Once it's in JIRA, you can route it to
the appropriate developer to fix the issue using JIRA's workflow engine.

## Installation

JIRA Exception Collector is a gem. To install:

    gem install jira-exception-collector

... or, add this to your Gemfile:

    gem jira-exception-collector

... then:

    bundle install


## Usage

This gem utilizes the [https://plugins.atlassian.com/583856](JIRA Issue Collector plugin).
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
use Rack::JiraExceptionCollector, "[collector url]"
````

By default, JIRA Exception Collector is enabled under production and staging environments.
To modify this, just supply an array of the environments you want exceptions to be logged:

````ruby
use Rack::JiraExceptionCollector, "[collector url]", %w(prod1 prod2 stage deploy)
````

## Compatibility with JIRA

Because this gem relies on the [https://plugins.atlassian.com/583856](JIRA Issue Collector plugin),
this gem is only compatible with the JIRA versions that the JIRA Issue Collector supports.

## Contributing

This is a pushmepullyou type of project. Fork it hard, push in your awesome sauce, then 
send in your pull request. Oh, don't forget to add tests.

## Copyright

Copyright (c) Rich Manalang and Atlassian, Inc. See LICENSE for details.