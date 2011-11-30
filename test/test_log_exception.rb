require 'helper'

class Rack::JiraExceptionCollector::TestLogException < Test::Unit::TestCase
  def setup
    @collector_url = "http://example.com/rest/collectors/1.0/template/form/ac29dace"
    FakeWeb.register_uri(:post, @collector_url,
                         :body => "Thanks for providing your feedback", :status => ["200", "OK"])

    @app = Rack::Lobster.new
    @collector = Rack::JiraExceptionCollector.new(@app, @collector_url){|c| 
      c.report_under << "test"
    }
    @request = Rack::MockRequest.new @collector
  end

  def make_it_crash
    ENV['RACK_ENV'] = 'test'
    env = Rack::MockRequest.env_for('/?flip=crash', :method => 'GET')
  end

  def test_no_collector_url_generates_exception
    assert_raise(Rack::JiraExceptionCollector::Error){ Rack::JiraExceptionCollector.new(@app) }
  end

  def test_collector_url_can_be_configured_in_block
    ENV['RACK_ENV'] = 'test'
    env = Rack::MockRequest.env_for('/?flip=crash', :method => 'GET')
    collector = Rack::JiraExceptionCollector.new(@app){|c|
      c.collector_url = @collector_url
      c.report_under << "test"
    }
    assert collector.collector_url == @collector_url
    assert_raise(RuntimeError) { collector.call(env) }
    assert_true env['jira.notified'], "JIRA exception created"
  end

  def test_exception_was_sent
    env = make_it_crash
    assert_raise(RuntimeError) { @collector.call(env) }
    assert_true env['jira.notified'], "JIRA exception created"
  end

  def test_exception_can_be_sent_from_a_custom_env
    ENV['RACK_ENV'] = "my_custom_env"
    env = Rack::MockRequest.env_for('/?flip=crash', :method => 'GET')
    collector = Rack::JiraExceptionCollector.new(@app, @collector_url){|c| c.report_under << "my_custom_env"}
    assert_raise(RuntimeError) { collector.call(env) }
    assert_true env['jira.notified'], "JIRA exception created"
  end

  def test_exception_can_be_filtered
    ENV["SUPER_SECRET_CODE"] = "My super secret code"
    env = make_it_crash
    collector = Rack::JiraExceptionCollector.new(@app, @collector_url){|c| 
      c.environment_filters << "SUPER_SECRET_CODE"
      c.report_under << "test"
    }
    assert_raise(RuntimeError) { collector.call(env) }
    assert_match /ENV\["SUPER_SECRET_CODE"\]\: \[FILTERED\]/, collector.error
  end

  def test_exception_can_be_filtered_with_more_than_one_filter
    ENV["SUPER_SECRET_CODE1"] = "My super secret code1"
    ENV["SUPER_SECRET_CODE2"] = "My super secret code2"
    env = make_it_crash
    collector = Rack::JiraExceptionCollector.new(@app, @collector_url){|c| 
      c.environment_filters = %w(SUPER_SECRET_CODE1 SUPER_SECRET_CODE2)
      c.report_under << "test"
    }
    assert_raise(RuntimeError) { collector.call(env) }
    assert_match /ENV\["SUPER_SECRET_CODE1"\]\: \[FILTERED\]/, collector.error
    assert_match /ENV\["SUPER_SECRET_CODE2"\]\: \[FILTERED\]/, collector.error
  end

  def test_rack_env_can_be_changed
    ENV['CUSTOM_ENV'] = 'test'
    env = Rack::MockRequest.env_for('/?flip=crash', :method => 'GET')
    collector = Rack::JiraExceptionCollector.new(@app, @collector_url){|c|
      c.report_under << "test"
      c.rack_environment = "CUSTOM_ENV"
    }
    assert_raise(RuntimeError) { collector.call(env) }
    assert_true env['jira.notified'], "JIRA exception created"
  end
end
