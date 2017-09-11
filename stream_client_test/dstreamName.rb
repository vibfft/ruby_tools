#!/usr/bin/env ruby 
#*******************************************************************************
#Author: Stephen Moon
#

class My_Streams


  def del_stream(depot,arg)

    streamName = ""

    `p4 streams`.each { |name| 

      name.split.each { |sname|
        if /^\/\/#{depot}\/#{arg}.+$/.match(sname)
         `p4 stream -d #{sname}`;
        end
      }

    }

  end

end


if ARGV.count != 2

  puts "Usage: ruby dStreamName.rb <streamDepot> <stream>"
  exit(1)

end

begin

  #puts "args: #{ARGV[0]}, #{ARGV[1]}"
  nStream = My_Streams.new
  nStream.del_stream(ARGV[0],ARGV[1])

rescue => ex
  
  puts "#{ex.class}: #{ex.message}"

end

