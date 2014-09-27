#!/usr/bin/env ruby
#
#
#
#
#

require "rubygems"
require 'sensu-plugin/check/cli'

class JmxHeapMemory < Sensu::Plugin::Check::CLI
  option :url,
    :short => '-u url',
    :long => '--url url',
    :description => 'Request URL',
    :default => "localhost:10080"
  
  option :warning,
    :description => "Metric naming scheme",
    :long => "--warning param",
    :default => 60000000
  
  option :critical,
    :description => "Metric naming scheme",
    :long => "--critical param",
    :default => 90000000

  def exec_jmx_client(script_path, url) 
    #return `java -jar cmdline-jmxclient-0.10.3.jar - localhost:10080 java.lang:type=Memory HeapMemoryUsage NonHeapMemoryUsage 2>&1`
    return `java -jar #{script_path}/cmdline-jmxclient-0.10.3.jar - #{url} java.lang:type=Memory HeapMemoryUsage 2>&1`
  end

  def run
    script_path = File.expand_path(File.dirname($0))
    heap_memory_usage = {}
    exec_jmx_client(script_path, config[:url]).split("\n").drop(1).each do | v |
      if /^([^:]+): (\d+)/ =~ v then
	heap_memory_usage[$1] = $2
      end
    end
    
    if heap_memory_usage["used"].to_i > config[:critical].to_i
      critical "MEM Critical #{heap_memory_usage["used"]} / #{heap_memory_usage["max"]}"
    elsif heap_memory_usage["used"].to_i > config[:warning].to_i
      warning "MEM Warning #{heap_memory_usage["used"]} / #{heap_memory_usage["max"]}"
    else
      ok "MEM OK #{heap_memory_usage["used"]} / #{heap_memory_usage["max"]}"
    end
    
  end
end
