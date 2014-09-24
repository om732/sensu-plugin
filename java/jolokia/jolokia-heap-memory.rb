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
  
  option :warning,
    :description => "Metric naming scheme",
    :long => "--warning param",
    :default => 1000000
  
  option :critical,
    :description => "Metric naming scheme",
    :long => "--critical param",
    :default => 2000000
    
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
    path = "/jolokia/read/java.lang:type=Memory/HeapMemoryUsage"
    return api_request(config[:url] + path)
  end

  def run
    params = get_memory
    
    timestamp = params[:timestamp]
    heap_memory_usage = params[:value][:used]
    heap_memory_max   = params[:value][:max]
    
    if heap_memory_usage > config[:critical].to_i
      critical "MEM Critical #{heap_memory_usage} / #{heap_memory_max}"
    elsif heap_memory_usage > config[:warning].to_i
      warning "MEM Warning #{heap_memory_usage} / #{heap_memory_max}"
    else
      ok "MEM OK #{heap_memory_usage} / #{heap_memory_max}"
    end
    
  end
end
