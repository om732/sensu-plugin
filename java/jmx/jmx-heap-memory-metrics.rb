#!/usr/bin/env ruby
#
#
#
#
#

require "rubygems"
require 'sensu-plugin/metric/cli'
require "rest-client"
require "time"

class JmxHeapMemoryMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :url,
    :short => '-u url',
    :long => '--url url',
    :description => 'Request URL',
    :default => "localhost:10080"

  option :scheme,
    :description => "Metric naming scheme",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.java"
    
  def exec_jmx_client(script_path, url, name)
    return `java -jar #{script_path}/cmdline-jmxclient-0.10.3.jar - #{url} java.lang:type=Memory #{name} 2>&1`
  end
  
  def parse(param)
    hash = {}
    param.split("\n").drop(1).each do | v |
      if /^([^:]+): (\d+)/ =~ v then
	hash[$1] = $2
      end
    end
    return hash
  end
  
  def run
    script_path = File.expand_path(File.dirname($0))
    timestamp = Time.now.to_i
    
    parse(exec_jmx_client(script_path, config[:url], "HeapMemoryUsage")).each{|k,v|
        output "#{config[:scheme]}.HeapMemoryUsage.#{k}", v, timestamp
    }
    
    parse(exec_jmx_client(script_path, config[:url], "NonHeapMemoryUsage")).each{|k,v|
        output "#{config[:scheme]}.NonHeapMemoryUsage.#{k}", v, timestamp
    }
    
    ok
  end
end
