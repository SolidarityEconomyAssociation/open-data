module SeOpenData
  module Utils
    require "csv"
    require "prawn"
    require "prawn/table"
    require "fileutils"

    # Document generator - generates errror reports
    #
    # It uses prawn to generate a formatted PDF
    class ErrorDocumentGenerator
      def initialize(title, introduction, name_header, domain_header, headers)
        @title_pdf = "docs/titledoc.pdf"
        @ids_pdf = "docs/idsdups.pdf"
        @fields_pdf = "docs/fieldups.pdf"
        @geo_pdf = "docs/geodups.pdf"
        @name_header = name_header
        @domain_header = domain_header
        @headers = headers

        pdf = Prawn::Document.new
        pdf.text title, :align => :center, :size => 25 # heading
        pdf.pad(10) { } #padding

        pdf.text introduction, :size => 12  # sum

        # Create the directory before rendering
        FileUtils.mkdir_p File.dirname(@title_pdf)
        pdf.render_file @title_pdf

        #create intro doc only if no other intro doc exists
      end

      def create_doc(title, description, similar_entries, filename)
        return if similar_entries.empty?
        pdf = Prawn::Document.new
        pdf.text title, :align => :center, :size => 25 # heading
        pdf.pad(10) { } #padding
        
        pdf.text description, :size => 12  # sum
        first = nil

        similar_entries.each { |subarr|
          #subbarr :: [row,row,row]
          name = subarr.first[@name_header].encode("Windows-1252", invalid: :replace, undef: :replace, replace: "")
          pdf.pad_top(30) { pdf.text name, :size => 15 } # mini heading name
          pdf.text "We think these are the same", :size => 10
          data = subarr.map { |row|
            #Remove empties
            rowarr = []
            row[@domain_header] = "" #rm domain
            #use only rows that have something in them
            @headers.each { |h| rowarr.push(row[h]) if (row[h] != nil && row[h] != "") }
            strrow = rowarr.join(",").encode("Windows-1252", invalid: :replace, undef: :replace, replace: "")
            first = [strrow] if first == nil

            [strrow]
          }
          pdf.table(data) do
            rows(0).width = 72
          end

          pdf.pad(5) { } #padding
          pdf.text "This is the entry we have kept", :size => 10 # heading
          pdf.text first.join
          first = nil


        }

        pdf.render_file filename
      end

      #similar_entries:: string => array of row
      def add_similar_entries_id(title, description, similar_entries)
        create_doc(title, description, similar_entries, @ids_pdf)
      end

      #similar_entries::
      def add_similar_entries_fields(title, description, similar_entries)
        create_doc(title, description, similar_entries, @fields_pdf)
      end

      #similar_entries::
      def add_similar_entries_fields_after_geo_uniform(title, description, similar_entries)
        create_doc(title, description, similar_entries, @geo_pdf)
      end

 
    end
  end
end
