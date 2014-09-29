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

class JmxThreadMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :url,
    :short => '-u url',
    :long => '--url url',
    :description => 'Request URL',
    :default => "localhost:10080"

  option :scheme,
    :description => "Metric naming scheme",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.java"
    
  def exec_jmx_client_thread(script_path, url, name)
    return `java -jar #{script_path}/cmdline-jmxclient-0.10.3.jar - #{url} java.lang:type=Threading ThreadCount TotalStartedThreadCount PeakThreadCount DaemonThreadCount`
  end
  
  def parse(param)
    hash = {}
    param.split("\n").each do | v |
      if /.*\s([^:]+): (\d+)/ =~ v then
	hash[$1] = $2
      end
    end
    return hash
  end
  
  def run
    script_path = File.expand_path(File.dirname($0))
    timestamp = Time.now.to_i
    
    parse(exec_jmx_client_thread(script_path, config[:url], config[:name])).each{|k,v|
        output "#{config[:scheme]}.#{config[:name]}.thread.#{k}", v, timestamp
    }
    
    ok
  end
end
