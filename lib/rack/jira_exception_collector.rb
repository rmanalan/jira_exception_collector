require 'rack/jira_exception_collector_version'
require 'net/http'
require 'net/https'
require 'uri'
require 'erb'
require 'ostruct'

module Rack
  class JiraExceptionCollector

    FILTER_REPLACEMENT = "[FILTERED]"

    class Error < StandardError; end

    attr_accessor :collector_url, :environment_filters, :report_under, :rack_environment, 
      :failsafe, :error

    def initialize(app, collector_url = nil)
      @app                 = app
      @collector_url       = collector_url
      @report_under        = %w(production staging)
      @rack_environment    = "RACK_ENV"
      @environment_filters = %w(AWS_ACCESS_KEY AWS_SECRET_ACCESS_KEY AWS_ACCOUNT SSH_AUTH_SOCK)
      @failsafe            = $stderr
      yield self if block_given?
      raise(Error, "You need to provide a collector URL") unless @collector_url
    end

    def call(env)
      status, headers, body =
        begin
          @app.call(env)
        rescue StandardError, LoadError, SyntaxError => boom
          notified = send_exception boom, env
          raise
        end
      send_exception env['rack.exception'], env if env['rack.exception']
      [status, headers, body]
    end

    def environment_filter_keys
      @environment_filters.flatten
    end

    def environment_filter_regexps
      environment_filter_keys.map do |key|
        "^#{Regexp.escape(wrapped_key_for(key))}$"
      end
    end
    private
    def report?
      @report_under.include?(rack_env)
    end

    def send_exception(exception, env)
      return true unless report?
      request = Rack::Request.new(env)

      options = {
        :url               => env['REQUEST_URI'],
        :params            => request.params,
        :framework_env     => rack_env,
        :notifier_name     => 'Rack::JiraExceptionCollector',
        :notifier_version  => VERSION,
        :environment       => environment_data_for(env),
        :session           => env['rack.session']
      }

      if result = post_to_jira(exception, options)
        if result.code == "200"
          env['jira.notified'] = true
        else
          raise Error, "Status: #{result.code} #{result.body.inspect}"
        end
      else
        raise Error, "No response from JIRA"
      end
    rescue Exception => e
      return unless @failsafe
      @failsafe.puts "Fail safe error caught: #{e.class}: #{e.message}"
      @failsafe.puts e.backtrace
      @failsafe.puts "Exception is #{exception.class}: #{exception.message}"
      @failsafe.puts exception.backtrace
      false
    end

    def rack_env
      ENV[@rack_environment] || 'development'
    end

    def document_defaults(error)
      {
        :error            => error,
        :environment      => ENV.to_hash,
        :backtrace        => backtrace_for(error),
        :url              => nil,
        :request          => nil,
        :params           => nil,
        :notifier_version => VERSION,
        :session          => {},
        :framework_env    => ENV['RACK_ENV'] || 'development',
        :project_root     => Dir.pwd
      }
    end

    def document_data(error, options)
      data = document_defaults(error).merge(options)
      [:params, :session, :environment].each{|n| data[n] = clean(data[n]) if data[n] }
      data
    end

    def document_for(exception, options={})
      data = document_data(exception, options)
      scope = OpenStruct.new(data).extend(ERB::Util)
      scope.instance_eval ERB.new(notice_template, nil, '-').src
    end    

    def notice_template
      ::File.read(::File.join(::File.dirname(__FILE__), 'exception.erb'))
    end

    BacktraceLine = Struct.new(:file, :number, :method)

    def backtrace_for(error)
      return "" unless error.respond_to? :backtrace
      lines = Array(error.backtrace).map {|l| backtrace_line(l)}
      if lines.empty?
        lines << BacktraceLine.new("no-backtrace", "1", nil)
      end
      lines
    end

    def backtrace_line(line)
      if match = line.match(%r{^(.+):(\d+)(?::in `([^']+)')?$})
        BacktraceLine.new(*match.captures)
      else
        BacktraceLine.new(line, "1", nil)
      end
    end

    def post_to_jira(exception,options={})
      uri = URI.parse(@collector_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == "https"
      request = Net::HTTP::Post.new(uri.request_uri)
      request['X-JIRA-Client-Name'] = "Rack::JiraExceptionCollector"
      @error = document_for(exception, options)
      request.set_form_data({ 
        "description" => "#{exception.class.name}: #{exception.message}",
        "webInfo" => @error
      })
      response = http.request(request)
    end

    def environment_data_for(env)
      data = {}
      ENV.each do |key,value|
        data[wrapped_key_for(key)] = value.inspect
      end
      env.each do |key,value|
        data["rack[#{key.inspect}]"] = value.inspect
      end
      data
    end

    def clean(hash)
      hash.inject({}) do |acc, (k, v)|
        acc[k] = (v.is_a?(Hash) ? clean(v) : filtered_value(k,v))
      acc
      end
    end

    def filters
      environment_filter_keys.flatten.compact
    end

    def filtered_value(key, value)
      if filters.any? {|f| key.to_s =~ Regexp.new(f)}
        FILTER_REPLACEMENT
      else
        value.to_s
      end
    end

    def wrapped_key_for(key)
      "ENV[#{key.inspect}]"
    end

    def extract_body(env)
      if io = env['rack.input']
        io.rewind if io.respond_to?(:rewind)
        io.read
      end
    end

  end
end
