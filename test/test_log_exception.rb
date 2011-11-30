require 'helper'

class Rack::JiraExceptionCollector::TestLogException < Test::Unit::TestCase
  def setup
    @collector_url = "http://example.com/rest/collectors/1.0/template/form/ac29dace"
    FakeWeb.register_uri(:post, @collector_url,
                         :body => "Thanks for providing your feedback", :status => ["200", "OK"])

    @app = Rack::Lobster.new
    @collector = Rack::JiraExceptionCollector.new @app, @collector_url
    @request = Rack::MockRequest.new @collector
  end

  def test_exception_was_sent
    ENV['RACK_ENV'] = 'test'
    env = Rack::MockRequest.env_for('/?flip=crash', :method => 'GET')
    assert_raise(RuntimeError) { @collector.call(env) }
    assert_true env['jira.notified'], "JIRA exception created"
  end

  def test_exception_can_be_sent_from_a_custom_env
    ENV['RACK_ENV'] = "my_custom_env"
    env = Rack::MockRequest.env_for('/?flip=crash', :method => 'GET')
    collector = Rack::JiraExceptionCollector.new @app, @collector_url, "my_custom_env"
    assert_raise(RuntimeError) { collector.call(env) }
    assert_true env['jira.notified'], "JIRA exception created"
  end
end
