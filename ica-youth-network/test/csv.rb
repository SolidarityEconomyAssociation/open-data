#!/usr/bin/env ruby
# This script controls a pipeline of processes that convert the original
# CSV data into the se_open_data standard, one step at a time.

require  "./load_config"

SRC_DIR = $config_map["SRC_CSV_DIR"]
GEN_DIR = $config_map["GEN_CSV_DIR"]
BIN_DIR = $config_map["SE_OPEN_DATA_BIN_DIR"]

# original src csv files 
csv_to_standard_1 = File.join(SRC_DIR, $config_map["ORIGINAL_CSV_1"])

# Intermediate csv files
added_ids = File.join(GEN_DIR, "with_ids.csv")
cleared_errors = File.join(GEN_DIR, "cleared_errors.csv")

# Output csv file
output_csv = $config_map["STANDARD_CSV"]


def clear_csv_errors(in_f:, out_f:)
  Config.gen_ruby_command(
    in_f,
    "clear_csv_errors.rb",
    nil,
    out_f,
    nil
  )  
end

def add_unique_ids(in_f:, out_f:)
  Config.gen_ruby_command(
    in_f,
    File.join(BIN_DIR, "csv/standard/add-unique-id.rb"),
    nil,
    out_f,
    nil
  )
end

def convert_for_coops_uk(in_f:, out_f:)
  Config.gen_ruby_command(
    in_f,
    "converter.rb",
    nil,
    out_f,
    nil
  )
end

if(!File.file?(output_csv))
  ## handle limesurvey
  # generate the cleared error file
  clear_csv_errors in_f: csv_to_standard_1, out_f: cleared_errors
  add_unique_ids in_f: cleared_errors, out_f: added_ids
  convert_for_coops_uk in_f: added_ids, out_f: output_csv
else
  puts "Refusing to overwrite existing output file: #{output_csv}"
end
