#!/usr/bin/env ruby
#*******************************************************************************
#
#Author: Stephen Moon
#

require 'logger'

class Proxy_Mon_Test

  @@threads = []
  def initialize(level,interval)

    @proxy_bin = "/home/smoon/p4_ws/clients/p4_main/dev-test/p4-test/t/proxy_diag/proxy/p4p" 
    @server_bin = "/home/smoon/p4_ws/clients/p4_main/dev-test/p4-test/t/proxy_diag/srv/p4d" 

    @proxy_root = "/home/smoon/p4_ws/clients/p4_main/dev-test/p4-test/t/proxy_diag/proxy/cache" 
    @server_root = "/home/smoon/p4_ws/clients/p4_main/dev-test/p4-test/t/proxy_diag/srv" 

    @proxy_op = ""
    @server_op = ""
    @level = level
    @interval = interval


  end

  def start_log(name, level, interval)

    log_file = "#{name}" + "_" + "#{level}" + "_" + "#{interval}.log"
    log_file = File.join(File::SEPARATOR,Dir.pwd, log_file)
    fd_log = File.open(log_file, File::WRONLY | File::APPEND | File::CREAT)
    log = Logger.new(fd_log)
    log.level = Logger::INFO

    return log

  end
    
  def start_thread(binary,option)
  
    output = "" 
    cmd = "#{binary} #{option}"
    puts "cmd: " + cmd
    server = fork do
             output = exec(cmd)
           end
    Process.detach(server)

    return output
  end

  def start_server

    @server_op = "-r #{@server_root} -p 1111 -vserver=3 -L p4log.txt"
    self.start_thread(@server_bin,@server_op)
    return "Server spawned"
    
  end

  def start_proxy

    @proxy_op = "-r #{@proxy_root} -vproxy.monitor.level=#{@level} -vproxy.monitor.interval=#{@interval} -t 1111 -p 2222 -L p4log.txt"
    self.start_thread(@proxy_bin,@proxy_op)
    return "Proxy spawned"

  end

  def start_proxy_monitor

    #output = self.start_thread(@proxy_bin,"-r " + @proxy_root + " -m")
    return output 

  end

  def thread_join

    @@threads.each { |n| n.join }
 
    return "Threads joined" 

  end
      

  def get_proxy_root

    return @proxy_root

  end

  def get_proxy_bin

    return @proxy_bin

  end

end


if ARGV.count != 3 

  puts "Usage: ruby proxy_mon.rb <level> <interval> <display>"
  puts
  puts "e.g. ruby proxy_mon.rb 1 5 3"

  exit(1)

end

nTest = Proxy_Mon_Test.new(ARGV[0],ARGV[1]) #level, interval

name = "proxym"
log = nTest.start_log(name, ARGV[0], ARGV[1]) #name, level, interval

begin

  msg = nTest.start_server

  puts msg
  log.info(msg)

  msg = nTest.start_proxy

  puts msg
  log.info(msg)

  prev_proxym = proxym = "" 
  while(1)

    output = ""
    #puts `lsof #{proxy_root}/pdb.monitor`
    if File.exists?(nTest.get_proxy_root + "/pdb.monitor")
      output = `lsof #{nTest.get_proxy_root}/pdb.monitor`
    end

    if output != "" or !proxym.match(/^lsof: status error .*$/) 
      proxym =`#{nTest.get_proxy_bin} -r #{nTest.get_proxy_root} -m#{ARGV[2]}`; 
      #proxym =nTest.start_proxy_monitor; 
      $stdout.flush
      puts "======================================================="
      puts "PREV: " + prev_proxym
      puts "CURR: " + proxym
      puts "======================================================="

      if proxym != prev_proxym and proxym != ""
        log.info("\n" + proxym)
      end

      prev_proxym = proxym

    end
  end

  log.close()

rescue => ex

  log.fatal(ex.message)
  puts "#{ex.class}: #{ex.message}"
  log.close()

end
