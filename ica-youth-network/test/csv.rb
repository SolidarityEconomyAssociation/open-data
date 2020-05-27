#!/usr/bin/env ruby
# This script controls a pipeline of processes that convert the original
# CSV data into the se_open_data standard, one step at a time.

require  "./load_config"

config_file = Dir.glob(__dir__+'/settings/{config,defaults}.txt').first # first existing match

Config = SeOpenData::Config.new(config_file)
  
SRC_DIR = Config.fetch "SRC_CSV_DIR"
GEN_DIR = Config.fetch "GEN_CSV_DIR"
BIN_DIR = Config.fetch "SE_OPEN_DATA_BIN_DIR"

# original src csv files 
csv_to_standard_1 = File.join(SRC_DIR, Config.fetch("ORIGINAL_CSV_1"))

# Intermediate csv files
added_ids = File.join(GEN_DIR, "with_ids.csv")
cleared_errors = File.join(GEN_DIR, "cleared_errors.csv")

# Output csv file
output_csv = Config.fetch "STANDARD_CSV"


# Performs the following on the input CSV stream
#
# - remove all single quotes not followed by a quote 
# - replace ' with empty
# - replace double quotes with single quote
# - make sure to place quote before the last two commas
#
# @param in_f [IO] - an IO stream reading a CSV document
# @param out_f [IO] - an IO stream writing the new CSV document
def clear_csv_errors(in_f:, out_f:)
  File.open(in_f) do |text|
    File.open(out_f, 'w') do |csv_out|
  
      error_detected = false
      headers = nil
      count = 0
      
      text.each_line do |line|
        if !headers # if there's an error in the headers there's an error in the file
          headers = line
          if line.include? "\""
            error_detected = true
          end
        end
        if error_detected
          line.encode!('UTF-8', 'UTF-8', :invalid => :replace)
          line.delete!("\xEF\xBB\xBF")
          line = line.sub('"','').sub(/.*\K\"/, '').gsub("'","").
                   gsub("\"\"","replaceMeWithQuote").gsub("\"","").gsub("replaceMeWithQuote","\"")
          csv_out.print(line) 
        # line = line.sub(/.*\K\"/, '')
        # strm = ","+line.split(',')[-2] +","+ line.split(',')[-1]
        # line.insert(line.index(strm),"\"")
        else
          csv_out.print(line)
        end
      end
    end
  end
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
