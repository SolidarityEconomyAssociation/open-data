#!/usr/bin/env ruby

require "optparse"
require "ostruct"
$default_file = "settings/defaults.txt"
$config_file = "settings/config.txt"


def parse_config(config_file,default_file)
  if (File.file?(config_file))
    conf_lines = File.read(config_file).split
  else
    conf_lines = File.read(default_file).split
  end
  conf = {}
  conf_lines.each do |line|
    if line.split("=").length > 1
      conf[line.split("=")[0]] = line.split("=")[1]
    end
  end
  conf
end


#find all configurable vars
class OptParse

  #
  # Return a structure describing the options.
  #
  def self.parse(args)
   
    parsed_config = parse_config($config_file,$default_file)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: $0 [options]"

      opts.separator ""
      opts.separator "Common options:"
      parsed_config.each do |k,v|
        options[k] = v
        opts.on("--"+k+"=PATH", "FILLER") do |arg|
          if (arg)
            options[k] = arg
          end
        end
      end

      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)
    options
  end  # parse()
end

$options = OptParse.parse(ARGV)

open($config_file, 'w') { |f|
  $options.each_pair do |k,v|
    f.puts "#{k}=#{v}"
  end
}
