# Document generator
# generates errror reports

#this uses prawn to generate a formatted PDF

module SeOpenData
  module Utils
    require "csv"
    require "prawn"
    require "prawn/table"

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

        pdf.render_file @title_pdf

        #create intro doc only if no other intro doc exists
      end

      def create_doc(title, description, similar_entries, filename)
        return if similar_entries.empty?
        pdf = Prawn::Document.new
        pdf.text title, :align => :center, :size => 25 # heading
        pdf.pad(10) { } #padding

        pdf.text description, :size => 12  # sum

        similar_entries.each { |subarr|
          #subbarr :: [row,row,row]
          name = subarr.first[@name_header].encode("Windows-1252", invalid: :replace, undef: :replace, replace: "")
          pdf.pad_top(30) { pdf.text (name + " duplicates"), :size => 15 } # mini heading name
          data = subarr.map { |row|
            #Remove empties
            rowarr = []
            row[@domain_header] = "" #rm domain
            #use only rows that have something in them
            @headers.each { |h| rowarr.push(row[h]) if (row[h] != nil && row[h] != "") }
            strrow = rowarr.join(",").encode("Windows-1252", invalid: :replace, undef: :replace, replace: "")
            [strrow]
          }
          pdf.table(data) do
            rows(0).width = 72
          end
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

      def combine_docs
        pdf_file_paths = [@title_pdf,@fields_pdf,@geo_pdf]
        Prawn::Document.generate("result.pdf", {:page_size => 'A4', :skip_page_creation => true}) do |pdf|
          pdf_file_paths.each do |pdf_file|
            if File.exists?(pdf_file)
              pdf_temp_nb_pages = Prawn::Document.new(:template => pdf_file).page_count
              (1..pdf_temp_nb_pages).each do |i|

                pdf.start_new_page(:template => pdf_file, :template_page => i)

              end
            end
          end
        end
        
        
      
    

      end
    end
  end
end
