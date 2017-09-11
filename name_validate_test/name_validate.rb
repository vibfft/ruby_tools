#!/usr/bin/env ruby 
#*******************************************************************************
#
#Author: Stephen Moon
#Date: 07/13/2011
#
#Summary: A function which create different permutations of
#         spec string names
#

class Specs 

  def initialize(depot,tmplate)

    @depot = "//" + depot + "/" 
    @file_read = tmplate 
    @branch_on = 0 
    @client_on = 0
    @label_on = 0 
    @stream_on = 0 

  end


  def determine_spec_type


    puts "1: #{@branch_on}, #{@client_on}, #{@label_on}, #{@stream_on}"

    fread = File.open(@file_read, 'r') 

    fread.each_line { |line|

      if /(^Branch:\s)(.+)$/.match(line)

        print "Branch: " + $2 + "\n"
        @branch_on = 1
	#break

      elsif /(^Client:\s)(.+)$/.match(line)

        print "Client: " + $2 + "\n"
        @client_on = 1
	#break

      elsif /(^Label:\s)(.+)$/.match(line)

        print "Label: " + $2 + "\n"
        @label_on = 1
	#break

      elsif /(^Stream:\s)(.+)$/.match(line)

        print "Stream: " + $2 + "\n"
        @stream_on = 1
	#break

      end
    }

    fread.close

    puts "2: #{@branch_on}, #{@client_on}, #{@label_on}, #{@stream_on}"

    if @branch_on == 1 || @client_on == 1 || @label_on == 1 || @stream_on == 1

      return 1

    else

      return 0

    end

  end


  def generate_specs

    
    spec_array = Array.new

    b_index = 33; e_index = 126  #visible characters
    rng_visible_chars = (b_index..e_index)

    #(1..rng_visible_chars.count).each { |n|
    (1..10).each { |n|

      if @label_on != 1
  
        fread = File.open(@file_read, 'r')
        fwrite = File.open(n.to_s + @file_read, 'w')
  
        #print "num #{n}:" 
        rng_visible_chars.count.times do  
  
          c = rand(rng_visible_chars.count) + b_index #has to sum e_index - b_index 
  
          if spec_array[n] == nil
  
            spec_array[n] = String.new
  
  	  if c == 37  #percent sign: %
  
              spec_array[n] << (c.chr + c.chr + '1'.to_s) 
  
  	  elsif c == 46 #period: .
  
              spec_array[n] << (c.chr + c.chr + c.chr) 
  
  	  elsif c == 42 #asterisk: *
  
              spec_array[n] << (c.chr + c.chr + c.chr) 
  
  	  else
  
              spec_array[n] << c.chr 
  
  	  end
  
          else
  
  	  if c == 37  #percent sign: %
  
              spec_array[n] << (c.chr + c.chr + '1'.to_s) 
  
  	  elsif c == 46 #period: .
  
              spec_array[n] << (c.chr + c.chr + c.chr) 
  
  	  elsif c == 42 #asterisk: *
  
              spec_array[n] << (c.chr + c.chr + c.chr) 
  
  	  else
  
              spec_array[n] << c.chr 
  
  	  end
  
          end
  
        end
  
        if @stream_on == 1
  
          spec_array[n].insert(0,@depot)
  
        end
        #print spec_array[n].inspect
        #print "\n\n\n"
  
        inView = 0
        fread.each_line { |line|
  
          if @branch_on == 1 && /(^Branch:\s)(.+)$/.match(line)
  
            fwrite.print "Branch: " + spec_array[n] + "\n"
  	  inView = 0
  
  	elsif @client_on == 1 && /(^Client:\s)(.+)$/.match(line)
  
            fwrite.print "Client: " + spec_array[n] + "\n"
  
  	elsif @client_on == 1 && /^View\:/.match(line)
 
	  fwrite.print line 
  	  inView = 1
  
  	elsif @client_on == 1 && inView == 1 && $_ !~ /^View\:/

          if /^(\s+\/\/)(.+)\/.*\s+\/\/(.+)\/.*$/.match(line)
  	    #puts "#{$1}, #{$2}, #{$3}"
  	    prefix = $1; depot = $2; cview = $3 
  
  	    fwrite.print "#{prefix}#{depot}/... //#{spec_array[n]}/...\n"
  
  	  end
  
        elsif @label_on == 1 && /(^Label:\s)(.+)$/.match(line)
  
            #fwrite.print "Label: " + spec_array[n] + "\n"
  
        elsif @stream_on == 1 && /(^Stream:\s)(.+)$/.match(line)
  
            fwrite.print "Stream: " + spec_array[n] + "\n"
  
  	else
  	  
  	  fwrite.print line
  
  	end
  
  
	} #end of each line read of the spec form

        fread.close
        fwrite.close

      end # lable_on if_end statement

      if @branch_on == 1

        system("p4 branch -i < #{n.to_s + @file_read}")

      elsif @client_on == 1	

        system("p4 client -i < #{n.to_s + @file_read}")

      elsif @label_on == 1

        system("p4 tag -l #{spec_array[n]} //depot/...")

      elsif @stream_on == 1

        system("p4 stream -i < #{n.to_s + @file_read}")

      end 

    } #end of permutation loop

  end

end


if ARGV.count != 2

  puts "Usage: ruby name_validate.rb <depot> <spec_tmplate>"
  puts
  puts "e.g. ruby name_validate.rb depot label_file"


  exit(1)

end

begin

  #puts "args: #{ARGV[0]}, #{ARGV[1]}"
  nSpec = Specs.new(ARGV[0],ARGV[1])

  #puts "What returns: #{nSpec.determine_spec_type}"

  
  if nSpec.determine_spec_type == 1

    nSpec.generate_specs

  end

rescue => ex
  
  puts "#{ex.class}: #{ex.message}"

end

