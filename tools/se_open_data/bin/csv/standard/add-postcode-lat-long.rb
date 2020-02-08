#!/usr/bin/env ruby
#
# $LOAD_PATH.unshift '/Volumes/Extra/SEA-dev/open-data-and-maps/data/tools/se_open_data/lib'
require 'optparse'
require 'ostruct'
require 'se_open_data'
require 'opencage/geocoder'



OutputStandard = SeOpenData::CSV::Standard::V1
APIStandard = SeOpenData::CSV::Standard::OpenCageAddressStandard

module HashExtensions
  def subhash(*keys)
    keys = keys.select { |k| key?(k) }
    Hash[keys.zip(values_at(*keys))]
  end
end

Hash.send(:include, HashExtensions)

class OptParse
  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.postcodeunit_cache = nil
    options.postcodeunit_global_cache = nil
    # @todo Some of these could be provided with a command line interface to set them:
    options.new_headers = OutputStandard::Headers.subhash(:geocontainer, :geocontainer_lat, :geocontainer_lon)
    options.input_csv_postcode_header = OutputStandard::Headers[:postcode]
    options.input_csv_country_header = OutputStandard::Headers[:country_name]
    options.address_headers = OutputStandard::Headers.subhash(:street_address,
      :locality,
      :region,
      :postcode,
      :country_name)

    options.geocoder_headers = APIStandard::Headers
    options.geocoder = APIStandard::OpenCageClass.new
    #should be in sync with STANDARD_CACHE_KEY_HEADERS

    #should the method replace the current address headers
    options.replace_address = true

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: $0 [options]"

      opts.separator ""
      opts.separator "Specific options:"

      # Mandatory argument.
      opts.on("--postcodeunit-cache FILENAME",
              "JSON file where OS postcode unit results are cached") do |filename|
        options.postcodeunit_cache = filename
      end

      # Mandatory argument.
      opts.on("--postcode-global-cache FILENAME",
              "CSV file where all the postcodes are kept (note that this will be a json in the future
              WIP)") do |filename|
        options.postcodeunit_global_cache = filename.empty? ? nil : filename
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
SeOpenData::CSV.add_postcode_lat_long(
  ARGF.read,
  $stdout,
  $options.input_csv_postcode_header,
  $options.input_csv_country_header,
  $options.new_headers,
  $options.postcodeunit_cache,
  {},
  $options.postcodeunit_global_cache,
  $options.address_headers,
  $options.replace_address,
  $options.geocoder_headers,
  $options.geocoder

)

# For debugging 

# input = File.open("/Volumes/Extra/SEA-dev/open-data-and-maps/data/dotcoop/domains2018-04-24/generated-data/experimental-new-server/csv/de-duplicated.csv", "r:utf-8")
# inputContent = input.read;
# input.close
# $stdout.reopen("/Volumes/Extra/SEA-dev/open-data-and-maps/data/dotcoop/domains2018-04-24/generated-data/experimental-new-server/standard.csv", "w")
# $stdout.sync = true

# $options = OptParse.parse(ARGV)
# SeOpenData::CSV.add_postcode_lat_long(
#   inputContent,
#   $stdout,
#   $options.input_csv_postcode_header,
#   $options.new_headers,
#   $options.postcodeunit_cache
# )