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

class JmxTomcat6Metrics < Sensu::Plugin::Metric::CLI::Graphite
  option :url,
    :short => '-u url',
    :long => '--url url',
    :description => 'Request URL',
    :default => "localhost:10080"

  option :scheme,
    :description => "Metric naming scheme",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.java"
  
  option :name,
    :short => '-n name',
    :long => "--name name",
    :description => "Catalina name"
    
  def exec_jmx_client_globale_request_processor(script_path, url, name)
    return `java -jar #{script_path}/cmdline-jmxclient-0.10.3.jar - #{url} Catalina:type=GlobalRequestProcessor,name=#{name} requestCount bytesSent errorCount processingTime bytesReceived 2>&1`
  end
  
  def exec_jmx_client_thread_pool(script_path, url, name)
    return `java -jar #{script_path}/cmdline-jmxclient-0.10.3.jar - #{url} Catalina:type=ThreadPool,name=#{name} currentThreadCount currentThreadsBusy maxThreads 2>&1`
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
    if !config[:name]
        unknown "name is required."
    end
    
    script_path = File.expand_path(File.dirname($0))
    timestamp = Time.now.to_i
    
    parse(exec_jmx_client_globale_request_processor(script_path, config[:url], config[:name])).each{|k,v|
        output "#{config[:scheme]}.#{config[:name]}.GlobalRequestProcessor.#{k}", v, timestamp
    }
    
    parse(exec_jmx_client_thread_pool(script_path, config[:url], config[:name])).each{|k,v|
        output "#{config[:scheme]}.#{config[:name]}.ThreadPool.#{k}", v, timestamp
    }
    
    ok
  end
end
