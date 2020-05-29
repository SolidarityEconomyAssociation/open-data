#!/usr/bin/env ruby
# This script controls a pipeline of processes that convert the original
# CSV data into the se_open_data standard, one step at a time.

require_relative "../../tools/se_open_data/lib/load_path"
require  "se_open_data/config"
require  "se_open_data/csv/clean_up"

config_file = Dir.glob(__dir__+'/settings/{config,defaults}.txt').first # first existing match

Config = SeOpenData::Config.new(config_file)

# original src csv files 
csv_to_standard_1 = File.join(Config.SRC_CSV_DIR, Config.ORIGINAL_CSV_1)

# Intermediate csv files
added_ids = File.join(Config.GEN_CSV_DIR, "with_ids.csv")
cleared_errors = File.join(Config.GEN_CSV_DIR, "cleared_errors.csv")

# Output csv file
output_csv = Config.STANDARD_CSV




# Adds a new last column `Id` and inserts in it a numeric index in each row.
def add_unique_ids(in_f:, out_f:)
  require 'csv'
  
  csv_opts = {}
  csv_opts.merge!(headers: true)
  File.open(in_f) do |in_s|
    File.open(out_f, 'w') do |out_s|
      csv_in = ::CSV.new(in_s, csv_opts)
      csv_out = ::CSV.new(out_s)
      headers = nil
      i = 0
      csv_in.each do |row|
        unless headers
          headers = row.headers
          headers.push("Id")
          csv_out << headers
        end
        row['Id'] = i
        i+=1
        csv_out << row
      end
    end
  end
end

# Transforms the rows from Co-ops UK schema to our standard
def convert_for_coops_uk(in_f:, out_f:)
  require_relative 'converter.rb'
  File.open(in_f) do |in_s|
    File.open(out_f, 'w') do |out_s|
      # Note the use of #read, convert expects a string so it
      # can remove BOMs. Possibly not required considering the
      # work in clear_csv_errors above.
      SpecializedCsvReader.convert(in_s.read, out_s)
    end
  end
end

if(File.file?(output_csv))
  puts "Refusing to overwrite existing output file: #{output_csv}"
else
  ## handle limesurvey
  # generate the cleared error file
  SeOpenData::CSV.clean_up in_f: csv_to_standard_1, out_f: cleared_errors
  add_unique_ids in_f: cleared_errors, out_f: added_ids
  convert_for_coops_uk in_f: added_ids, out_f: output_csv
end
