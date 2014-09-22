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

class JvmMemoryMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :url,
    :short => '-u url',
    :long => '--url url',
    :description => 'Request URL',
    :default => "http://localhost:8778"

  option :scheme,
    :description => "Metric naming scheme",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.Memory"
    
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
  
  def get_memory
    path = "/jolokia/read/java.lang:type=Memory"
    return api_request(config[:url] + path)
  end

  def run
    params = get_memory
    
    timestamp = params[:timestamp]
    heap_memory_usage = params[:value][:HeapMemoryUsage]
    non_heap_memory_usage = params[:value][:NonHeapMemoryUsage]
    
    heap_memory_usage.each do |key, value|
        output "#{config[:scheme]}.HeapMemoryUsage.#{key}", value, timestamp
    end
    non_heap_memory_usage.each do |key, value|
        output "#{config[:scheme]}.NonHeapMemoryUsage.#{key}", value, timestamp
    end
    ok
  end
end
