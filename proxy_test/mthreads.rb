#!/usr/bin/env ruby 
#*******************************************************************************
#
#Author: Stephen Moon
#
# encoding: utf-8

require 'thread'
require 'logger'

class Mthreads

  def initialize(num_threads,port,user)

    @num_threads = num_threads
    @p4port = port 
    @p4user = user
    @cmd_prefix = "p4 -p #{@p4port} -u #{@p4user}"
    @dir_name = "thread_files"
    @cmds_array = []
    @cmds_map = {}

  end

  def create_file(fcount, log)

    first_Dir = File.join(File::SEPARATOR,Dir.pwd,@dir_name)
    log.debug(first_Dir)
    if !File.directory?(first_Dir)
      Dir.mkdir(first_Dir)
    end

    second_Dir = File.join(File::SEPARATOR,first_Dir,fcount.to_s)
    log.debug(second_Dir)
    if !File.directory?(second_Dir)
      Dir.mkdir(second_Dir)
    end

    nFile = ""
    if self.depot_exists(log) != 1
      third_Dir = File.join(File::SEPARATOR,second_Dir,'depot')
      log.debug(third_Dir)
      if !File.directory?(third_Dir)
        Dir.mkdir(third_Dir)
      end
      nFile = File.join(File::SEPARATOR,third_Dir,fcount.to_s)
    else
      nFile = File.join(File::SEPARATOR,second_Dir,fcount.to_s)
    end
    
    log.debug(nFile)
      
    file_write = File.new(nFile,'w')
    file_write.puts '$File:$'
    file_write.puts 'File ID: $Id$'
    file_write.puts 'File Header: $Header$'
    file_write.puts 'File Author: $Author$'
    file_write.puts 'File Date: $Date$'
    file_write.puts 'File DateTime: $DateTime$'
    file_write.puts 'File Change: $Change$'
    file_write.puts 'File File: $File$'
    file_write.puts 'File Revision: $Revision$'

    count = 0
    while(count < 10000000) 
      file_write.print "This is " + fcount.to_s + "\n\n"
      file_write.print "Loop count is " + count.to_s + "\n\n"
      count += 1
    end
    file_write.flush
    file_write.close

    return nFile

  end

  def get_filename(count, log)

    nFile = ""
    if self.depot_exists(log) != 1
      nFile = File.join(File::SEPARATOR,Dir.pwd,@dir_name,count.to_s,'depot',count.to_s)
    else
      nFile = File.join(File::SEPARATOR,Dir.pwd,@dir_name,count.to_s,count.to_s)
    end

    log.debug(nFile)
    return nFile

  end

  def depot_exists(log)

    number = self.join_passed_array_n_exec([@cmd_prefix,'depots'],log)
 
    count = depot = 0 
    number.each { |n|
      count += 1
      #print "depot: #{n}\n"
      if n.match(/^Depot\s(\S+)\s.*$/)
        if $1 == "depot"
          depot = 1
        end
      end
    }

    if count > 1 and depot == 1 #threads_file/0/depot/0
      return 0
    elsif count == 1 and depot == 1 #threads_file/0/0
      return 1
    elsif count > 1 and depot != 1 #first make depot "depot" and then threads_file/0/depot/0
      return 2
    end

  end

  def file_add(client_name, filename, log)

    self.join_passed_array_n_exec([@cmd_prefix,'-c',client_name,'add','-t','+k',filename],log)
    self.join_passed_array_n_exec([@cmd_prefix,'-c',client_name,'submit','-d','added_' + filename,filename],log)
    log.info(filename + " added successfully")

  end

  def create_client(count, log)
   
    nclient_array = Array.new 
    output = self.join_passed_array_n_exec([@cmd_prefix,'client','-o','c' + count.to_s],log)

    log.debug(output)
    output.each { |n|
      if n.match(/(^Root:\s+)(\S+)$/)
        prefix = $1; suffix = $2
        c = File.join(File::SEPARATOR,suffix,@dir_name,count.to_s)
        nclient_array.push(prefix + c) 
      else
        nclient_array.push(n)
      end
    }

    newspec = nclient_array.join

    log.debug(newspec)
    IO.popen("#{@cmd_prefix} client -i",'w') { |pipe|
      pipe.print(newspec)
      pipe.close
    }

    return ('c' + count.to_s)

  end

  def cmds_hash(count, log)

    client_name = "-c c" + count.to_s
    needs_resolve = ['merge','copy','ignore','move']
    no_need_to_submit = ['print','fstat','filelog','populate','annotate','sync']
    filename = self.get_filename(count,log)

    log.info("Filename: " + filename)
    integ_cmds_map = { 'merge'    => 'integ;resolve -am',
                       'copy'     => 'integ;resolve -at',
                       'ignore'   => 'integ;resolve -ay',
                       'move'     => 'move;resolve -at',
                       'populate' => 'populate',
                       'branch'   => 'integ' 
                     }

    #randonmized test case is split one character at a time
    #and then it is mapped to a command according to the dictionary
    #in cmds_db method
    @cmds_array[rand(@cmds_array.length)].split("").each { |c|
      #splits the command and arg number delimited by ":"
      if @cmds_map[c].match(/(\w+)\:(\w+)/)

        cmd_name = $1; args = $2

        log.info("cmd: " + cmd_name + " args: " + args)
        if args.to_i == 2

          if needs_resolve.include?(cmd_name)  
            (cmd_name, resolve_cmd) = integ_cmds_map[cmd_name].split(";")

            a = self.join_passed_array_n_exec([@cmd_prefix, client_name, cmd_name,
                                               filename,filename + count.to_s],log)
            puts
            puts a
            log.info("Integ command: ")
            log.info(a)

            b = self.join_passed_array_n_exec([@cmd_prefix, client_name, resolve_cmd],log)
            puts
            puts b
            log.info("Resolve command: ")
            log.info(b)

          else
            cmd_name = integ_cmds_map[cmd_name]            
            c = self.join_passed_array_n_exec([@cmd_prefix, client_name,cmd_name,
                                         filename,filename + count.to_s],log)
            puts
            puts c
            log.info("Integ without resolve: ")
            log.info(c)
          end

        else
          log.info("cmd: " + cmd_name + " filename: " + filename)
          d = ''
          if cmd_name == 'sync'
            d = self.join_passed_array_n_exec([@cmd_prefix, client_name, cmd_name,' -f ', filename],log)
          elsif cmd_name == 'print'
            d = self.join_passed_array_n_exec([@cmd_prefix, client_name, cmd_name, filename, ' > /dev/null'],log)
          else
            d = self.join_passed_array_n_exec([@cmd_prefix, client_name, cmd_name, filename],log)
          end

          puts
          puts d
          log.info("No submit: ")
          log.info(d)

        end #end of different arg for different cmds
       
        #sleep(1)
        if args.to_i == 2
          e = self.join_passed_array_n_exec([@cmd_prefix, client_name,
                                      'submit', '-d', 
                                      cmd_name + '_' + filename + '_' + filename + count.to_s],log)
          puts
          puts e 
          log.info("Two arg submit: ")
          log.info(e)
        elsif (!no_need_to_submit.include?(cmd_name))
          f = self.join_passed_array_n_exec([@cmd_prefix, client_name,
                                      'submit', '-d', 
                                      cmd_name + '_' + filename],log)
          puts
          puts f 
          log.info("One arg submit: ")
          log.info(f)
        end #end of submit

      end #end of regex match statement
    }
    
  end

  def revert_all_files(log) 

    files = self.join_passed_array_n_exec([@cmd_prefix,'revert','//depot/...'],log)
    puts files 
    log.debug(files)

  end

  def obliterate_all_files(log)

    ofiles = self.join_passed_array_n_exec([@cmd_prefix,'obliterate','-y','//depot/...'],log)
    puts ofiles 
    log.debug(ofiles)

  end

  def remove_all_client_files(log) 

    cfiles = self.join_passed_array_n_exec(['rm','-rf','thread_files'],log)
    puts cfiles 
    log.debug(cfiles)

  end
    

  def delete_clients(log)

    clients = self.join_passed_array_n_exec([@cmd_prefix,'clients'],log)
    #puts clients
    log.debug(clients)
    clients.each { |n|
      if n.force_encoding("UTF-8").ascii_only?
        if n.match(/^Client\s+(c\S+)\s+.*$/)
          self.join_passed_array_n_exec([@cmd_prefix,'client','-f','-d',$1],log)
          puts "Client #{$1} deleted"
          log.debug("Client #{$1} deleted")
        end 
      end
    }    

  end

  def delete_pending_changes(log)

    changes = self.join_passed_array_n_exec([@cmd_prefix,'changes','-s','pending','//depot/...'],log)
    log.debug(changes)
    changes.each { |n|
      puts n
      if n.match(/^Change\s(\S+)\son\s\d{4}\/\d{2}\/\d{2}\sby\s\S+\@(\S+)\s\*pending\*\s.*$/)
        self.join_passed_array_n_exec([@cmd_prefix,'-c',$2,'change','-d',$1],log)
        puts "Change #{$1} deleted"
        log.debug("Change #{$1} deleted")
      end 
    }    

  end

  def join_passed_array_n_exec(array, log)

    o_array = Array.new
    joined_cmd = array.join(' ')
    log.debug(joined_cmd)

    `#{joined_cmd}`.lines { |n|
          o_array.push(n + "\n") 
    }

    return o_array
        
  end

  def cmds_db

    @cmds_array = ['spf']
    
    @cmds_map = {'a' => 'add:1',
                 'b' => 'branch:2',
                 'c' => 'copy:2',
                 'd' => 'delete:1',
                 'e' => 'edit:1',
                 'f' => 'fstat:1',
                 'g' => 'ignore:2',
                 'i' => 'integ:2',
                 'l' => 'filelog:1',
                 'm' => 'merge:2',
                 'o' => 'annotate:1',
                 #'p' => 'populate:2',
                 'p' => 'print:1',
                 #'r' => 'move:2',
                 's' => 'sync:1'
                }

  end

    
end

if ARGV.count != 3 

  puts "Usage: ruby mthreads.rb <num_threads> <port> <user>"
  puts
  puts "e.g. ruby mthreads.rb 10 1111 smoon"

  exit(1)

end

nthread = Mthreads.new(ARGV[0],ARGV[1],ARGV[2])

threads = []

num_threads = (ARGV[0]).to_i

log_file = ARGV[2] + "_" + ARGV[1] + "_" + ARGV[0] + ".log"
log_file = File.join(File::SEPARATOR,Dir.pwd, log_file)
fd_log = File.open(log_file, File::WRONLY | File::APPEND | File::CREAT)
log = Logger.new(fd_log)
log.level = Logger::INFO

nthread.revert_all_files(log)
nthread.obliterate_all_files(log)
nthread.remove_all_client_files(log)
nthread.delete_pending_changes(log)
nthread.delete_clients(log)

nFile = ''
num_threads.times { |f|

  nFile = nthread.create_file(f,log)
  client_name = nthread.create_client(f,log)
  nthread.file_add(client_name, nFile,log)

}

puts "Created clients and added files"

nthread.cmds_db()

puts "Initialized db"

begin

  cthread = Thread.new do 
    count = 0
    num_threads.times { |i|
      Thread.current['tCount'] = count
      nthread.cmds_hash(count,log)
      count += 1
    }

  end

  threads << cthread

  threads.each { |thread| cthread.join; puts cthread['tCount'] }

  log.close()  
rescue => ex

  log.fatal(ex.message)
  puts "#{ex.class}: #{ex.message}" 
  log.close()

end
