def uk_postcode?(s)
  uk_postcode_regex = /([Gg][Ii][Rr] 0[Aa]{2})|((([A-Za-z][0-9]{1,2})|(([A-Za-z][A-Ha-hJ-Yj-y][0-9]{1,2})|(([A-Za-z][0-9][A-Za-z])|([A-Za-z][A-Ha-hJ-Yj-y][0-9][A-Za-z]?))))\s?[0-9][A-Za-z]{2})/
  uk_postcode_regex.match(s)
end

# OX1 = 51.75207,-1.25769
# OX2 =

module SeOpenData
  module CSV
    require "se_open_data/csv/schemas"

    # The latest output schema
    StdSchema = SeOpenData::CSV::Schemas::Versions[-1]

    def self.add_postcode_lat_long(infile:, outfile:,
                                   api_key:, lat_lng_cache:, postcode_global_cache:,
                                   replace_address: false, csv_opts: {}, use_ordinance_survey: false)
      input = File.open(infile, "r:bom|utf-8")
      output = File.open(outfile, "w")
      geocoder = SeOpenData::CSV::Standard::GeoapifyStandard::Geocoder.new(api_key)
      geocoder_headers = SeOpenData::CSV::Standard::GeoapifyStandard::Headers
      subhash = lambda do |hash, *keys|
        keys = keys.select { |k| hash.key?(k) }
        Hash[keys.zip(hash.values_at(*keys))]
      end
      headers = StdSchema.to_h
      SeOpenData::CSV._add_postcode_lat_long(
        input,
        output,
        StdSchema.field(:postcode).header,
        StdSchema.field(:country_name).header,
        subhash.call(headers,
                     :geocontainer,
                     :geocontainer_lat,
                     :geocontainer_lon),
        lat_lng_cache,
        csv_opts,
        postcode_global_cache,
        subhash.call(headers,
                     :street_address,
                     :locality,
                     :region,
                     :postcode,
                     :country_name),
        replace_address,
        geocoder_headers,
        geocoder,
        use_ordinance_survey
      )
    ensure
      input.close
      output.close
    end

    # Transforms a CSV file, adding latitude and longitude fields
    # obtained by geocoding a postcode field.
    #
    # - should take in which headers to change with which standard STANDARD_HEADERS from global
    # - should have boolean weather to change addresses
    # - postcode unit cache is legacy?
    #
    # TODO: this is becoming a noodle factory, fix and clean it
    #
    # TODO: abstract away so that you only pass the standard and the io and it does the work for you
    #
    # @param input_io [IO, File] file or stream to read CSV data from
    # @param output_io [IO, File] file or stream to write CSV data to
    # @param input_csv_postcode_header [String] header of input CSV field containing postcodes
    # @param input_country_header [String] header of input CSV field containing country names
    # @param new_headers [Hash<Symbol,String>] IDs and header names of output CSV fields
    # @param postcodeunit_cache [String] JSON file where OS postcode unit results are cached (passed to
    # {SeOpenData::RDF::OsPostcodeUnit::Client})
    # @param csv_opts [Hash] options to pass to CSV when parsing input_io (in addition to `headers: true`)
    # @param global_postcode_cache [String] optional path to a JSON file where all the postcodes are kept (passed to {SeOpenData::RDF::OsPostcodeGlobalUnit::Client})
    # @param address_headers [Hash<Symbol,String] IDs and header names ...
    # @param replace_address [Boolean] set to true if we should replace the current address headers && set to "force" if we should replace the headers with whatever the geocoder finds (i.e.replace the field even if the geocoder finds nothing)
    # @param geocoder_headers [Hash<Symbol,String] IDs and header names ...
    # @param geocoder_standard [#get_new_data(search_key,country)] a geocoder
    # @param use_ordinance_survey [Boolean] set true to use ordinance survey to geocode UK postcodes
    def self._add_postcode_lat_long(
      input_io,
      output_io,
      input_csv_postcode_header,
      input_country_header,
      new_headers,
      postcodeunit_cache,
      csv_opts = {},
      global_postcode_cache = nil,
      address_headers,
      replace_address,
      geocoder_headers,
      geocoder_standard,
      use_ordinance_survey
    )
      csv_opts.merge!(headers: true)
      csv_in = ::CSV.new(input_io, **csv_opts)
      csv_out = ::CSV.new(output_io)
      allHeaders = new_headers.merge(address_headers)
      postcode_client = SeOpenData::RDF::OsPostcodeUnit::Client.new(postcodeunit_cache)
      global_postcode_client = nil
      if global_postcode_cache != nil
        global_postcode_client = SeOpenData::RDF::OsPostcodeGlobalUnit::Client.new(global_postcode_cache, geocoder_standard)
      end

      #add global postcode
      headers = nil
      row_count = csv_in.count
      csv_in.rewind
      prog_ctr = SeOpenData::Utils::ProgressCounter.new("Fetching geodata... ", row_count, $stderr)
      csv_in.each do |row|
        unless headers
          headers = row.headers + new_headers.values.reject { |h| row.headers.include? h }
          csv_out << headers
        end
        prog_ctr.step
        # Only run if matches uk postcodes
        postcode = row[input_csv_postcode_header]
        country = row[input_country_header]
        if use_ordinance_survey && uk_postcode?(postcode) # UCOMMENT TO USE ORDINANCE SURVEY FOR UK POSTCODE GEOLOCATION
          pcunit = postcode_client.get(postcode)
          loc_data = {
            geocontainer: pcunit ? pcunit[:within] : nil,
            geocontainer_lat: pcunit ? pcunit[:lat] : nil,
            geocontainer_lon: pcunit ? pcunit[:lng] : nil,
            country_name: "United Kingdom",
          }
          new_headers.each { |k, v|
            row[v] = loc_data[k]
          }
        elsif global_postcode_client #geocode using global geocoder
          #standardize the address if indicated
          headersToUse = {}

          if replace_address != false
            headersToUse = allHeaders
          else
            headersToUse = new_headers
          end

          #need to match standard h
          address = []

          address_headers.each { |k, v|
            address.push(row[v])
          }
          #return with the headers i want to replace
          pcunit = global_postcode_client.get(address, country) #assigns both address_headers field

          if pcunit == nil
            csv_out << row
            next
          end
          headersToUse.each { |k, v|
            #only replace information about address, do not delete information
            #or maybe you should delete it when you want to compare locations?
            if replace_address == "force"
              row[v] = pcunit[geocoder_headers[k]]
            elsif (pcunit[geocoder_headers[k]] != nil && pcunit[geocoder_headers[k]] != "")
              row[v] = pcunit[geocoder_headers[k]]
            end
          }
        end

        csv_out << row
      end

      if global_postcode_client
        global_postcode_client.finalize(0)
      end
    end
  end
end
