# Merges domains in rows of CSV that contain identical IDs.
# A duplicate is defined as having the same keys as a previous row.
# OR if all other fields except the key field and the domain field are equal

# $LOAD_PATH.unshift '/Volumes/Extra/SEA-dev/open-data-and-maps/data/tools/se_open_data/lib'
require "se_open_data"
require "optparse"
require "ostruct"

class OptParse
  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.keys = SeOpenData::CSV::Standard::V1::UniqueKeys.map { |sym| SeOpenData::CSV::Standard::V1::Headers[sym] }
    options.domainHeader = SeOpenData::CSV::Standard::V1::Headers[:homepage]
    options.nameHeader = SeOpenData::CSV::Standard::V1::Headers[:name]

    options.original_csv = nil

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: $0 [options]"

      opts.separator ""
      opts.separator "Specific options:"

      # Mandatory argument.
      opts.on("--original-csv FILENAME",
              "Original Csv File before geo uniformication") do |filename|
        options.original_csv = filename.empty? ? nil : filename
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

SeOpenData::CSV.merge_and_de_duplicate(
  ARGF.read,
  $stdout,
  $stderr,
  $options.keys,
  $options.domainHeader,
  $options.nameHeader,
  $options.original_csv
)

# For debugging

# input = File.open("/Volumes/Extra/SEA-dev/open-data-and-maps/data/dotcoop/domains2018-04-24/generated-data/experimental-new-server/csv/outlets.csv", "r:utf-8")
# inputContent = input.read;
# input.close
# $stdout.reopen("/Volumes/Extra/SEA-dev/open-data-and-maps/data/dotcoop/domains2018-04-24/generated-data/experimental-new-server/csv/de-duplicated.csv", "w")
# $stderr.reopen("/Volumes/Extra/SEA-dev/open-data-and-maps/data/dotcoop/domains2018-04-24/generated-data/experimental-new-server/csv/ignored-duplicates.csv", "w")
# $stdout.sync = true
# $stderr.sync = true
# SeOpenData::CSV.merge_and_de_duplicate(inputContent, $stdout, $stderr, keys, domainHeader, nameHeader)
