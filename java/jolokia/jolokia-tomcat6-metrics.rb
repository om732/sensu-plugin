#!/usr/bin/env ruby
#
#
#
#
#

require "rubygems"
require 'sensu-plugin/metric/cli'
require "rest-client"
require "json"
require "uri"

class JvmCatalinaMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :url,
    :short => '-u url',
    :long => '--url url',
    :description => 'Request URL',
    :default => "http://localhost:8778"

  option :scheme,
    :description => "Metric naming scheme",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.Catalina"
    
  option :name,
    :short => '-n name',
    :long => "--name name",
    :description => "Catalina name"
    
  def api_request(url)
    begin
      request = RestClient::Resource.new(url)
      JSON.parse(request.get, :symbolize_names => true)
    rescue RestClient::ResourceNotFound
      warning "Resource not found: #{url}"
    rescue Errno::ECONNREFUSED
      warning "Connection refused"
    rescue RestClient::RequestFailed
      warning "Request failed"
    rescue RestClient::RequestTimeout
      warning "Connection timed out"
    rescue RestClient::Unauthorized
      warning "Missing or incorrect Sensu API credentials"
    rescue JSON::ParserError
      warning "Joloki returned invalid JSON"
    end
  end
  
  def get_global_request_processor
    path = "/jolokia/read/Catalina:type=GlobalRequestProcessor,name=#{config[:name]}/requestCount,bytesSent,errorCount,processingTime,bytesReceived"
    return api_request(URI.escape(config[:url] + path))
  end
  
  def get_thread_pool
    path = "/jolokia/read/Catalina:type=ThreadPool,name=#{config[:name]}/currentThreadCount,currentThreadsBusy,maxThreads"
    return api_request(URI.escape(config[:url] + path))
  end

  def run
    if !config[:name]
        critical "name is required."
    end
    
    item = get_global_request_processor
    timestamp = item[:timestamp]
    item[:value].each do |key, val|
      output "#{config[:scheme]}.#{config[:name]}.GlobalRequestProcessor.#{key}", val, timestamp
    end
    
    item = get_thread_pool
    timestamp = item[:timestamp]
    item[:value].each do |key, val|
      output "#{config[:scheme]}.#{config[:name]}.ThreadPool.#{key}", val, timestamp
    end
    
    ok
  end
end
