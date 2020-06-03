require 'csv'

module SeOpenData

  # FIXME move classes into own files
  
  # A mechanism to hide implementation from the DSL
  # by closing over variables.
  class DslProxy
    def initialize(**attrs)
      attrs.each do |key, val|
        raise "parameter key '#{key}' must have a callable value" unless
          val.respond_to? :call

        #puts "defining proxy method #{key}"
        method = key.to_sym
        define_singleton_method method do |*args, **kargs, &block|
          #puts ">> a #{args} k #{kargs} b #{block}"
          val.call(*args, **kargs, &block)
        end
      end
    end
  end

  # Primarily this defines a DSL for describing CSV translations.
  #
  # Later it could also do other things.
  class CSV
#    @registry = {}
    
#    def self.registry
#      @registry
#    end

    def self.new_field(**attr)
      Field.new(**attr)
    end

    
    # This implements the top-level DSL for CSV schema
    def self.schema(id:, name: id, &block)
      fields = []
      dsl = DslProxy.new(
        field: Proc.new { |**attr| fields.push(new_field **attr) },
      )
      dsl.instance_eval(&block)
      return Schema.new(id: id, name: name, fields: fields)
    end

    # This implements the top-level DSL for CSV conversions.
    def self.conversion(from_schema, to_schema,
                        input_csv_opts: {}, output_csv_opts: {},
                        &block)
      pipeline = []

      # Parameters map method to expose to #call-able objects
      # accepting an input stream and an output stream as parameters.
      dsl = DslProxy.new(
        each_row: Proc.new do |&blk|
          pipeline.push(
            RowConverter.new(
              from_schema, to_schema,
              blk,
              input_csv_opts: input_csv_opts,
              output_csv_opts: output_csv_opts,
            )
          )
        end,
        transform: Proc.new do |callable|
          pipeline.push(callable)
        end,
        input_csv_opts: Proc.new do |**opts|
          input_csv_opts = input_csv_opts.merge(opts)
        end,
        output_csv_opts: Proc.new do |**opts|
          output_csv_opts = output_csv_opts.merge(opts)
        end,
      )
      dsl.instance_eval(&block)

      return Conversion.new(from_schema, to_schema, pipeline)
    end

    # Implements a CSV conversion
    class Conversion
      attr_reader :pipeline
      def initialize(from_schema, to_schema, pipeline)
        @from = from_schema
        @to = to_schema
        @pipeline = pipeline
      end

      def convert(in_data, out_data)
        in_data = File.open(in_data, 'r') if in_data.is_a? String
        out_data = File.open(out_data, 'w') if out_data.is_a? String

        @pipeline.each.with_index(1) do |callable, ix|
          if ix < @pipeline.size
            file = tempfile
            file.open do |out_str|
              callable.call(in_data, out_str)
            end
            in_data.close
            in_data = file.open
          else
            callable.call(in_data, out_data)
          end
        end
        
      ensure
        in_data.close
        out_data.close
      end

      protected

      def tempfile
        Tempfile.new('csv-conversion')
      end
    end

    # Just maps one schema to another
    class NopConverter
      def initialize(from_schema, to_schema, input_csv_opts: {}, output_csv_opts: {})
        @from_schema = from_schema
        @to_schema = to_schema

        # FIXME ensure this has headers: false or the returned data changes class!
        @input_csv_opts = input_csv_opts
        
        @output_csv_opts = output_csv_opts      
      end

      def call(input, output)
        csv_in = ::CSV.new(input, **@input_csv_opts)
        csv_out = ::CSV.new(output, **@output_csv_opts)

        # Read the input headers, and validate them
        headers = csv_in.shift
        field_map = @from_schema.validate_headers(headers) # This may throw

        # Write the output headers
        csv_out << @to_schema.field_headers
        
        csv_in.each do |row|
          # This may throw if validation fails
          id_hash = @from_schema.id_hash(row, field_map)

          # this may throw
          csv_out << @to_schema.row(new_id_hash)
        end
      end
    end
    
    # Wraps an each_row block from the DSL
    class RowConverter
      attr_reader :block, :from_schema, :to_schema, :input_csv_opts, :output_csv_opts
      
      def initialize(from_schema, to_schema, block, input_csv_opts: {}, output_csv_opts: {})
        @from_schema = from_schema
        @to_schema = to_schema

        # FIXME ensure this has headers: false or the returned data changes class!
        @input_csv_opts = input_csv_opts
        
        @output_csv_opts = output_csv_opts      
        @block = block
      end

      def call(input, output)
        csv_in = ::CSV.new(input, **@input_csv_opts)
        csv_out = ::CSV.new(output, **@output_csv_opts)

        # Read the input headers, and validate them
        headers = csv_in.shift
        raise RuntimeError, "no headers in input stream" unless headers
        field_map = @from_schema.validate_headers(headers) # This may throw

        # Write the output headers
        csv_out << @to_schema.field_headers
        
        csv_in.each do |row|
          # This may throw if validation fails
          id_hash = @from_schema.id_hash(row, field_map)

          new_id_hash = @block.call(id_hash)

          # this may throw
          csv_out << @to_schema.row(new_id_hash)
        end
      end
    end

    
    # Defines a CSV Schema
    class Schema
      def initialize(id:, name:, fields:)
        @id = id.to_sym
        @name = name.to_s
        @fields = normalise_fields(fields)
        
        # Pre-compute these. Trust that nothing will get mutated!
        @field_ids = @fields.collect { |field| field.id }
        @field_headers = @fields.collect { |field| field.header }
      end

      attr_reader :id, :name, :fields, :field_ids, :field_headers

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
        # FIXME validate!
        # check number of fields
        # check type?
        raise ArgumentError, "field_map must have #{@fields.size} elements" unless
          field_map.size == @fields.size
        row.each.with_index do |datum, datum_ix|
          field_ix = field_map[datum_ix]

          unless field_ix.nil?
            raise ArgumentError, "invalid field index #{field_ix} for schema :#{@id}" if
              field_ix < 0 || field_ix >= @fields.size

            field = @fields[field_ix]

            raise ArgumentError, "duplicate field index #{field_ix}" if hash.has_key? field.id

            hash[field.id] = datum
          end
        end
        
        return hash
      end

      # Turns a hash keyed by field ID into an array of values
      #
      # The values are validated during this process.
      def row(id_hash)
        # FIXME validate!
        @fields.collect do |field|
          raise ArgumentError, "no value for field '#{field.id}'" unless
            id_hash.has_key? field.id
          id_hash[field.id]
        end
      end
    end

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
  end
end
