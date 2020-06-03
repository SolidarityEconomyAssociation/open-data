require_relative "../lib/load_path"
require "se_open_data/csv"
require "minitest/autorun"

Minitest::Test::make_my_diffs_pretty!

describe SeOpenData::CSV do

  # Describe an input schema
  a_schema = SeOpenData::CSV.schema(id: "foreign") do
    field id: "foo",
          header: "Foo",
          desc: "just a foo"
    
    field id: "bar",
          header: "Bar",
          desc: "a bar"
    
    field id: "barBaz",
          header: "Bar Baz",
          desc: "bar and baz"
  end

  # And an output schema
  b_schema = SeOpenData::CSV.schema(id: "local") do
    field id: "foo",
          header: "Foo",
          desc: "just a foo"
    
    field id: "barNbaz",
          header: "Bar & Baz",
          desc: "bar and baz"
  end
  
  # Define a simple conversion
  inopts = {skip_blanks: false, col_sep: "\t"}
  outopts = {force_quotes: true}
  conversion = SeOpenData::CSV.conversion(a_schema, b_schema,
                                          input_csv_opts: inopts,
                                          output_csv_opts: outopts) do

    # Modify the input options
    input_csv_opts skip_blanks: true
    output_csv_opts force_quotes: false
    
    each_row do | foo:, bar:, barBaz: |
      
      # Output row
      {
        foo: bar,
        barNbaz: barBaz.to_i - bar.to_i
      }
    end
  end
     
  describe "the test conversion" do
    
    it "should have a pipeline with two callables which performs the correct transform" do
      value(conversion.pipeline.size).must_equal 1
      value(conversion.pipeline[0].respond_to? :call).must_equal true

      # Test the RowConverter.block 
      in_data = {foo: 1, bar: 2, barBaz: 3}
      expected_out = {foo: 2, barNbaz: 1}
      value(conversion.pipeline[0].block.call(in_data)).must_equal expected_out

      # A CSV with a blank line to skip
      in_csv = <<-HERE
Foo\tBar\tBar Baz
10\t2\t30

20\t4\t60
HERE
      
      expected_csv = <<-HERE
Foo,Bar & Baz
2,28
4,56
HERE
      out_csv = ''
      StringIO.open(in_csv, 'r') do |in_str|
        StringIO.open(out_csv, 'w') do |out_str|
          conversion.convert(in_str, out_str)
        end
      end
      value(out_csv).must_equal expected_csv
    end
  end
  
end

                 
