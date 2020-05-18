#!/usr/bin/env ruby
# This script controls a pipeline of processes that convert the original
# CSV data into the se_open_data standard, one step at a time.

require  "./load_config"

# original src csv files 
csv_to_standard_1 = $config_map["SRC_CSV_DIR"]+$config_map["ORIGINAL_CSV_1"]


# csv_to_standard_1 CSV files
added_ids = $config_map["GEN_CSV_DIR"] + "with_ids.csv"
cleared_errors = $config_map["GEN_CSV_DIR"] + "cleared_errors.csv"

# local scripts to help with the conversion:
original_converter_loc_script = "converter.rb"
error_cleaner_loc_script = "clear_csv_errors.rb"

# library to be used in the pipeline:
add_ids_lib_script = $config_map["SE_OPEN_DATA_BIN_DIR"] + "csv/standard/add-unique-id.rb" 

# cache files
#postcode_cache = 


if(!File.file?($config_map["STANDARD_CSV"]))
  # generate the cleared error file
  Config.gen_ruby_command(
    csv_to_standard_1,
    error_cleaner_loc_script,
    nil,
    cleared_errors,
    nil
  )
  Config.gen_ruby_command(
    cleared_errors,
    add_ids_lib_script,
    nil,
    added_ids,
    nil
  )
  Config.gen_ruby_command(
    added_ids,
    original_converter_loc_script,
    nil,
    $config_map["STANDARD_CSV"],
    nil
  )
else
  puts "Work is already done "
end
