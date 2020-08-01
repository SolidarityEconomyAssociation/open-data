# coding: utf-8
require "csv"

module SeOpenData
  module CSV
    N_NUMBERS_COMPARE = 5

    def self.floor_float(input, digits = 1)
      input.divmod(10 ** -digits).first / (10 ** digits).to_f
    end
    #make matches
    # @param keys - array to find the matches for
    # @param n - the first n characters to check for equivalence
    # @returns - an array of matches (in the form of [[match,match],[match,match],[match]])
    # go through the array for each element and make a matched array for the lat lon fields, after that remove all matched from array and repeat
    def self.get_all_matches(keys, n)
      kcopy = keys
      kmatches = []
      keys.each { |k|
        kmatch = []
        kcopy.each { |kc|
          kmatch += [kc] if (floor_float(k["Geo Container Latitude"].to_f, n) ==
                             floor_float(kc["Geo Container Latitude"].to_f, n) && floor_float(k["Geo Container Longitute"].to_f, n) ==
                                                                                  floor_float(kc["Geo Container Longitute"].to_f, n))
        }
        next if kmatch == []
        kcopy -= kmatch
        kmatches.push(kmatch)
        break if kcopy.length == 0
      }
      return kmatches
    end
    # Merge domains and de-duplicate rows of CSV
    #
    # A duplicate is defined as having the same lat lon as another row
    #
    # @param input_io          Input CSV (must have headers)
    # @param output_io         CSV with duplicates removed
    # @param domainHeader      Array of column heading for the domain
    # @param nameHeader        Array of column heading for the name
    # @param lat      the latitude header
    # @param lon      the longitude header
    def CSV.merge_and_remove_latlon_dups(
      input_io,
      output_io,
      domainHeader,
      nameHeader,
      lat,
      lon
    )
      domainHeader = "Website"
      small_words = %w(on the and ltd limited llp community SCCL)
      small_word_regex = /\b#{small_words.map { |w| w.upcase }.join("|")}\b/

      csv_opts = {}
      csv_opts.merge!(headers: true)
      csv_in = ::CSV.new(input_io, csv_opts)
      csv_out = ::CSV.new(output_io)
      #make a map of name => [{lat,lon,row}]
      name_map = {}
      #make matches list for each name
      #merge them
      #print new file with merged
      #print latlongdups doc
      headers = nil
      csv_in.each do |row|
        unless headers
          headers = row.headers
        end

        name = row.field(nameHeader)
        name = name.
          gsub(/\s/, "").
          upcase.
          gsub(small_word_regex, "").
          sub(/\([[:alpha:]]*\)/, "").
          gsub(/[[:punct:]]/, "").
          sub(/COOPERATIVE/, "COOP").
          sub("SCCL", "")

        if !name_map.has_key? name
          name_map[name] = [row]
        else
          name_map[name].push(row)
        end
      end

      nm = []
      dups = []

      name_map.each { |k, v|
        matches = get_all_matches(v, N_NUMBERS_COMPARE)
        matches.each { |match|
          first = match.first
          if match.length > 1
            dups += [match]
            match.each { |row|
              unless first == row
                # add to domain
                existingDomain = first.field(domainHeader)
                domain = row.field(domainHeader)
                if !existingDomain.include?(domain)
                  first[domainHeader] += ";" + domain #SeOpenData::CSV::Standard::V1::SubFieldSeparator + domain
                end
              end
            }
          end
          nm.push first
        }
      }

      #print new file with merged
      csv_out << headers
      nm.each do |r|
        csv_out << r
      end

      #print latlongdups doc
      err_doc_client = SeOpenData::Utils::ErrorDocumentGenerator.new("Duplicates DotCoop Title Page", "The process of importing data from DotCoop requires us to undergo several stages of data cleanup, fixing and rejecting some incompatible data that we cannot interpret.

        The following documents describe the 3 stages of processing and lists the corrections and decisions made.
        
        These documents make it clear how SEA is interpreting the DotCoop data and can be used by DotCoop to suggest corrections they can make to the source data.
        
        [We can provide these reports in other formats, csv, json etc. as requested, which may assist you using the data to correct the source data.]", nameHeader, domainHeader, headers)

      err_doc_client.add_similar_entries_latlon("Duplicates by Lat and Lon fields after Geocoding", "This is part of the cleaning with Geocoding service step.
        
        Entries found with the first " + N_NUMBERS_COMPARE.to_s + " digits of their lon/lat fields equal and the same name will be merged together.",
                                                dups)
    end
  end
end
