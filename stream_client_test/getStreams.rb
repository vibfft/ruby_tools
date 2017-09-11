#!/usr/bin/env ruby 
#*******************************************************************************
#

def getStream(depot,fh)

  `p4 streams`.each { |s|

     s.split.each do |token|

       puts "each: #{token}"
       if /(^\/\/#{depot}\/)$/.match(token)

         fh.puts "#{$1}"

       elsif /(^\/\/#{depot}\/\S+)$/.match(token)

         fh.puts "#{$1}"

       end

     end

   } 

end


if ARGV.count != 1

  puts "Usage: ruby getStreams.rb <streamDepot>"
  exit(1)

end

begin

  fh = File.open("streamNames.txt","w")
  getStream(ARGV[0],fh)

rescue => ex

  puts "#{ex.class}: #{ex.message}"
 
end 
