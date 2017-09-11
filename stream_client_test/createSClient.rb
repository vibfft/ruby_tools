#!/usr/bin/env ruby 
#*******************************************************************************
#Author: Stephen Moon
#Date: 04/28/2011
#
#Summary: A function which create different permutations of
#         streams string names which comes after a stream depot name 
#
#*******************************************************************************

class Clients

  def initialize(depot,tmplate)

    @sdepot = "//" + depot + "/" 
    @file_read = tmplate 

  end


  def generate_clients

    stream_array = Array.new

    b_index = 32; e_index = 126  #visible characters
    rng_visible_chars = (b_index..e_index)

    #(1..rng_visible_chars.count).each { |n|
    (1..10000).each { |n|

      fread = File.open(@file_read, 'r')
      fwrite = File.open(n.to_s + @file_read, 'w')

      #print "num #{n}:" 
      rng_visible_chars.count.times do  

        c = rand(rng_visible_chars.count) + b_index #has to sum e_index - b_index 

        if stream_array[n] == nil

          stream_array[n] = String.new

	  if c == 37  #percent sign: %

            stream_array[n] << (c.chr + c.chr + '1'.to_s) 

	  elsif c == 46 #period: .

            stream_array[n] << (c.chr + c.chr + c.chr) 

	  elsif c == 42 #asterisk: *

            stream_array[n] << (c.chr + c.chr + c.chr) 

	  else

            stream_array[n] << c.chr 

	  end

        else

	  if c == 37  #percent sign: %

            stream_array[n] << (c.chr + c.chr + '1'.to_s) 

	  elsif c == 46 #period: .

            stream_array[n] << (c.chr + c.chr + c.chr) 

	  elsif c == 42 #asterisk: *

            stream_array[n] << (c.chr + c.chr + c.chr) 

	  else

            stream_array[n] << c.chr 

	  end

        end

      end
      stream_array[n].insert(0,@sdepot)
      #print stream_array[n].inspect
      #print "\n\n\n"


      fread.each_line { |line|

        if /(^Stream:\s)(.+)$/.match(line)

          fwrite.print "Stream: " + stream_array[n] + "\n"

        else

          fwrite.print line

        end

      }
      fread.close

      fwrite.close
      system("p4 stream -i < #{n.to_s + @file_read}")

    }

  end

end


if ARGV.count != 2

  puts "Usage: ruby createSClient.rb <streamDepot> <clientspec_tmplate>"
  puts
  puts "e.g. ruby createSClient.rb Ace sClient.txt"


  exit(1)

end

begin

  #puts "args: #{ARGV[0]}, #{ARGV[1]}"
  nStream = Clients.new(ARGV[0],ARGV[1])
  nStream.generate_clients

rescue => ex
  
  puts "#{ex.class}: #{ex.message}"

end

