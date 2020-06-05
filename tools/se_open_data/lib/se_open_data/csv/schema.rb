require 'csv'

module SeOpenData
  module CSV

    # Defines a CSV Schema
    #
    # This also defines a DSL for describing CSV translations via {self.converter}
    class Schema
      DEFAULT_INPUT_CSV_OPTS = {
        # Headers need to be off or else the logic needs to be changed.
        headers: false, 
        skip_blanks: true
      }
      DEFAULT_OUTPUT_CSV_OPTS = {
      }
      
      attr_reader :id, :name, :version, :description, :comment, :fields, :field_ids, :field_headers
      
      def initialize(id:, name: id, version: 0, description: '', comment: '', fields:)
        @id = id.to_sym
        @name = name.to_s
        @fields = normalise_fields(fields)
        @version = version
        @description = description
        
        # Pre-compute these. Trust that nothing will get mutated!
        @field_ids = @fields.collect { |field| field.id }
        @field_headers = @fields.collect { |field| field.header }
      end

      # Ensures that the fields are all instances of {Field}
      def normalise_fields(fields)
        last_ix = -1
        fields.collect.with_index do |field, ix|
          last_ix = ix
          if field.is_a? Field
            field.add_index(ix)
          else
            Field.new(index: ix, **field)
          end
        end
      rescue => error
        raise ArgumentError, "Field with index #{last_ix} cannot be normalised, #{error.message}"
      end

      # Assumes that:
      # - Header names match the schema exactly
      # - There is one header which matches each field in the schema
      # - But there are no duplicate headers
      # - There may be unused headers
      #
      # @raise ArgumentError if any schema fields can't be matched or are duplicated
      # @return an array of row field indexes for schema field, or nil if that row field
      # is not included
      def validate_headers(headers) #FIXME
        invalids = []
        map = Array.new(@fields.size)
        @fields.each.with_index do |field, ix|
          header_ix = headers.find_index(field.header)
          if header_ix.nil?
            invalids.push "'#{field.header}' is missing"
          else
            if headers.rindex(field.header) != header_ix
              invalids.push "'#{field.header}' is duplicated"
            else
              map[ix] = header_ix
            end
          end
        end

        return map if invalids.empty?

        raise ArgumentError, "invalid header fields #{headers}: #{invalids.join('; ')}"
      end

      # Turns an array of values into a hash keyed by field ID
      #
      # The values are validated during this process.
      
      # @param row [Array] - an array of data values
      #
      # @param field_map [Array<Integer, nil>] - an array of schema
      # field indexes mapping to that row field (or nil when the
      # schema does not include that row field). 
      #
      # @return [Hash<Symbol => Object>] the row data hashed by field ID
      def id_hash(row, field_map)
        hash = {}
        used = []
        # FIXME validate!
        # check number of fields
        # check type?
        raise ArgumentError, "row must have #{@fields.size} elements, not #{row.size}" unless
          row.size == @fields.size
        raise ArgumentError, "field_map must have #{@fields.size} elements" unless
          field_map.size == @fields.size
        
        @fields.each.with_index do |field, field_ix|
          datum_ix = field_map[field_ix]

          if datum_ix.nil?
            raise ArgumentError, "nil field index #{datum_ix} for schema :#{@id}"
          end
          if datum_ix < 0 || datum_ix >= row.size
            raise ArgumentError, "invalid field index #{datum_ix} for schema :#{@id}"
          end
          if used[datum_ix]
            raise ArgumentError, "duplicate field index #{datum_ix} for schema :#{@id}"
          end

          hash[field.id] = row[datum_ix]
          used[datum_ix] = true
        end
        
        return hash
      end

      # Turns a hash keyed by field ID into an array of values
      #
      # The values are validated during this process.
      def row(id_hash)
        # FIXME validate!
        id_hash = id_hash.clone # Make a copy so we don't mutate anything outside
        
        row = @fields.collect do |field|
          raise ArgumentError, "no value for field '#{field.id}'" unless
            id_hash.has_key? field.id
          id_hash.delete field.id
        end

        return row if id_hash.empty?
        
        raise ArgumentError,
              "hash keys do not match '#{@id}' schema field IDs: #{id_hash.keys.join(', ')}"
      end

      # This implements the top-level DSL for CSV conversions.
      def self.converter(from_schema:, to_schema:,
                         input_csv_opts: DEFAULT_INPUT_CSV_OPTS,
                         output_csv_opts: DEFAULT_OUTPUT_CSV_OPTS,
                         &block)

        return Converter.new(
          from_schema: from_schema,
          to_schema: to_schema,
          input_csv_opts: input_csv_opts,
          output_csv_opts: output_csv_opts,
          &block)
      end

      # Defines a field in a schema
      class Field
        attr_reader :id, :index, :header, :desc, :comment
        
        def initialize(id:, index: -1, header:, desc: '', comment: '')
          @id = id.to_sym
          @index = index.to_i
          @header = header.to_s
          @desc = desc.to_s
          @comment = comment.to_s
        end

        # Creates a new field instance with the same values but the given index
        def add_index(index)
          Field.new(id: id, index: index, header: @header, desc: @desc, comment: comment)
        end
      end

      # Defines a number of file conversion styles
      #
      # Most notably {#each_row} which performs schema validation
      # and tries to facilitate simple mapping of fields
      class Converter
        attr_reader :from_schema, :to_schema, :block
        
        def initialize(from_schema:,
                       to_schema:,
                       input_csv_opts: {},
                       output_csv_opts: {},
                       &block)
          @from_schema = from_schema
          @to_schema = to_schema
          @input_csv_opts = input_csv_opts
          @output_csv_opts = output_csv_opts
          @block = block
        end

        # Accepts files or streams
        def stream(in_data, out_data, &block)
          in_data = File.open(in_data, 'r') if in_data.is_a? String
          out_data = File.open(out_data, 'w') if out_data.is_a? String

          yield(in_data, out_data)
          
        ensure
          in_data.close
          out_data.close
        end

        def each_row(input, output)
          stream(input, output) do |inputs, outputs|
            csv_in = ::CSV.new(inputs, **@input_csv_opts)
            csv_out = ::CSV.new(outputs, **@output_csv_opts)
            
            # Read the input headers, and validate them
            headers = csv_in.shift
            field_map = @from_schema.validate_headers(headers) # This may throw
            
            # Write the output headers
            csv_out << @to_schema.field_headers
            
            csv_in.each do |row|
              # This may throw if validation fails
              id_hash = @from_schema.id_hash(row, field_map)

              new_id_hash =
                begin
                  block_given? ? yield(id_hash) : @block.call(id_hash)
                rescue ArgumentError => e
                  # Try to reword the error helpfully from:
                  match = e.message.match(/missing keywords?: (.*)/)
                  if match
                    # To this:
                    raise ArgumentError,
                          "block keyword parameters do not match '#{@from_schema.id}'"+
                          " CSV schema field ids: #{match[1]}"
                  else
                    raise
                  end
                end
              
              # this may throw
              csv_out << @to_schema.row(new_id_hash)              
            end
          end
        end

        alias convert each_row
      end
    end
  end
end
