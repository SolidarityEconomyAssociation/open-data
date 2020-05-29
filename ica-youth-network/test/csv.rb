#!/usr/bin/env ruby
# This script controls a pipeline of processes that convert the original
# CSV data into the se_open_data standard, one step at a time.

require_relative "../../tools/se_open_data/lib/load_path"
require_relative "converter.rb"
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






if(File.file?(output_csv))
  puts "Refusing to overwrite existing output file: #{output_csv}"
else
  ## handle limesurvey
  # generate the cleared error file
  SeOpenData::CSV.clean_up in_f: csv_to_standard_1, out_f: cleared_errors
  SpecializedCsvReader.add_unique_ids input: cleared_errors, output: added_ids
  SpecializedCsvReader.convert input: added_ids, output: output_csv
end
