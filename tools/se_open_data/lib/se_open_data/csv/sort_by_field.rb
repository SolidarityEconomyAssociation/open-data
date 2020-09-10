# coding: utf-8
require "csv"
require "levenshtein"

module SeOpenData
  module CSV

    # Sort data by a particular field
    #
    #
    # @param input_io          Input CSV (must have headers)
    # @param output_io         sorted CSV
    # @param field             field to sort by
    # @param descending        if false sorts by ascending order
    # @param is_int            if true parses field as int
    def CSV.sort_by_field(
      input_io,
      output_io,
      field,
      descending,
      is_int
    )
      csv_opts = {}
      csv_opts.merge!(headers: true)
      csv_in = ::CSV.new(input_io, **csv_opts)
      csv_out = ::CSV.new(output_io)

      headers = nil
      csv_in.sort_by { |row| is_int ? row[field].to_i : row[field] }.each { |row|
        unless headers
          csv_out << row.headers
          headers = row.headers
        end
        csv_out << row
      }
    end
  end
end
