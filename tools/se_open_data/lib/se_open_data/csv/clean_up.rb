require 'csv'

module SeOpenData
  module CSV
    # General cleaning-up of a CSV file.
    #
    # Performs the following on the input CSV stream
    #
    # - remove spurious UTF-8 BOMs sometimes written by MS Excel (maybe? FIXME test this.)
    # - remove all single quotes not followed by a quote 
    # - replace ' with empty
    # - replace double quotes with single quote
    # - make sure to place quote before the last two commas
    #
    # @param in_f [IO] - an IO stream reading a CSV document (with a header row)
    # @param out_f [IO] - an IO stream writing the new CSV document
    def self.clean_up(in_f:, out_f:)
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
            else
              csv_out.print(line)
            end
          end
        end
      end
    end
  end
end
