#!/usr/bin/env ruby
# This script controls a pipeline of processes that convert the original
# CSV data into the se_open_data standard, one step at a time.

require_relative "../../tools/se_open_data/lib/load_path"
require  "se_open_data/config"

config_file = Dir.glob(__dir__+'/settings/{config,defaults}.txt').first # first existing match

Config = SeOpenData::Config.new(config_file)
  
SRC_DIR = Config.SRC_CSV_DIR
GEN_DIR = Config.GEN_CSV_DIR
BIN_DIR = Config.SE_OPEN_DATA_BIN_DIR

# original src csv files 
csv_to_standard_1 = File.join(SRC_DIR, Config.ORIGINAL_CSV_1)

# Intermediate csv files
added_ids = File.join(GEN_DIR, "with_ids.csv")
cleared_errors = File.join(GEN_DIR, "cleared_errors.csv")

# Output csv file
output_csv = Config.STANDARD_CSV


# Performs the following on the input CSV stream
#
# - remove spurious UTF-8 BOMs sometimes written by MS Excel (maybe? FIXME test this.)
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
  clear_csv_errors in_f: csv_to_standard_1, out_f: cleared_errors
  add_unique_ids in_f: cleared_errors, out_f: added_ids
  convert_for_coops_uk in_f: added_ids, out_f: output_csv
end
