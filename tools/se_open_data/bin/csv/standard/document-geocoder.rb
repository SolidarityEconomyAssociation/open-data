#!/usr/bin/env ruby
#
# $LOAD_PATH.unshift '/Volumes/Extra/SEA-dev/open-data-and-maps/data/tools/se_open_data/lib'
require "optparse"
require "ostruct"
require "se_open_data"
require "opencage/geocoder"
require "shellwords"

OutputStandard = SeOpenData::CSV::Standard::V1
APIStandard = SeOpenData::CSV::Standard::GeoapifyStandard

# TODO: need to pass the geocoding standard as well
class OptParse
  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.postcodeunit_cache = nil
    options.converted = nil
    options.docs_folder = "docs/"
    options.api_key = "geoapifyAPI.txt"

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: $0 [options]"

      opts.separator ""
      opts.separator "Specific options:"

      # Mandatory argument.
      opts.on("--postcode-global-cache FILENAME",
              "CSV file where all the postcodes are kept (note that this will be a json in the future
              WIP)") do |filename|
        # raise "no such file: #{filename}" unless File.exists?(filename)
        options.postcodeunit_global_cache = filename
      end

      opts.on("--docs-folder FILENAME",
              "generated documentation folder") do |filename|
        # raise "no such file: #{filename}" unless File.exists?(filename)
        options.docs_folder = filename
      end

      opts.on("--converted FILENAME",
              "the file used for geocoding") do |filename|
        # raise "no such file: #{filename}" unless File.exists?(filename)
        options.converted = filename
      end

      opts.separator ""
      opts.separator "Common options:"

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

# Production

$options = OptParse.parse(ARGV)
pass = SeOpenData::Utils::PasswordStore.new(use_env_vars: false)
geoapify = APIStandard::Geocoder.new(pass.get $options.api_key || File.read("../../APIs/geoapifyAPI.txt"))
geoapify.gen_geo_report($options.postcodeunit_global_cache, 0.05, $options.docs_folder, $options.converted, ["Website"])
