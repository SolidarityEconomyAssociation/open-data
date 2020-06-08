require 'csv'

module SeOpenData
  module CSV
    class Schema
      class Types

        def self.normalise_email(val, default: '')
          val.to_s =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i? val : default # FIXME report mismatches
        end
        
        def self.normalise_url(val, default: '') # FIXME use something off the shelf
          val = val.to_s
          
          if val && !val.empty?
            val.match(/https?\S+/) do |m|
              return m[0]
            end

            val.match(/^\s*(www\.\S+)/) do |m|
              return "http://#{m[1]}"
            end

            add_comment("This doesn't look like a website: #{val} (Maybe it's missing the http:// ?)")
            return default
          end
        end

        def self.normalise_float(val, default: 0)
          val =~ /^[+-]?\d+[.]\d+$/? val : default
        end

        # Splits the field by the given delimiter, passes to the block for mapping,
        #
        # Parses the block like a CSV row, with default delimiter
        # character ';' and quote character "'" (needed for values
        # with the delimiter within). The escape character is '\\'
        #
        # @param val [String] the multi-value field
        # @param delim [String] the sub-field delimiter character
        # @param quote [String] the sub-field qupte character
        def self.multivalue(val, delim: ';', quote: "'")
          subfields = ::CSV.parse_line(val, quote_char: quote, col_sep: delim)
          new_subfields = subfields.collect {|field| yield field.strip, subfields }
          ::CSV.generate_line(new_subfields,
                              quote_char: quote, col_sep: delim).chomp
        end

        # FIXME implemented here as a stopgap, should be elsewhere
        def self.add_comment(str)
          $stderr.puts str
        end
      end
    end
  end
end
