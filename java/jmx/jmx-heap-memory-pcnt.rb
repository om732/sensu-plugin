#!/usr/bin/env ruby
#
#
#
#
#

require "rubygems"
require 'sensu-plugin/check/cli'

class JmxHeapMemoryPcnt < Sensu::Plugin::Check::CLI
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
    
    used_percent = (heap_memory_usage['used'].to_f / heap_memory_usage['max'].to_f * 100).round(1)
    
    if used_percent.to_f > config[:critical].to_f
      critical "#{used_percent}% #{heap_memory_usage["used"]} / #{heap_memory_usage["max"]}"
    elsif used_percent.to_f > config[:warning].to_f
      warning "#{used_percent}% #{heap_memory_usage["used"]} / #{heap_memory_usage["max"]}"
    else
      ok "#{used_percent}% #{heap_memory_usage["used"]} / #{heap_memory_usage["max"]}"
    end
    
  end
end
