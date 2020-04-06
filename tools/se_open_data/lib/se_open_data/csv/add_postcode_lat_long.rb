
def uk_postcode?(s)
  uk_postcode_regex = /([Gg][Ii][Rr] 0[Aa]{2})|((([A-Za-z][0-9]{1,2})|(([A-Za-z][A-Ha-hJ-Yj-y][0-9]{1,2})|(([A-Za-z][0-9][A-Za-z])|([A-Za-z][A-Ha-hJ-Yj-y][0-9][A-Za-z]?))))\s?[0-9][A-Za-z]{2})/
  uk_postcode_regex.match(s)
end

# OX1 = 51.75207,-1.25769
# OX2 = 

module SeOpenData
  module CSV

    #should take in which headers to change with which standardSTANDARD_HEADERS from global
    #should have boolean weather to change addresses
    #postcode unit cache is legacy?
    #TODO: this is becoming a noodle factory, fix and clean it
    #TODO: abstract away so that you only pass the standard and the io and it does the work for you
    def CSV.add_postcode_lat_long(input_io, output_io, input_csv_postcode_header, input_country_header,
      new_headers, postcodeunit_cache, csv_opts = {},
      global_postcode_cache,address_headers,replace_address,geocoder_headers,geocoder_standard)
      csv_opts.merge!(headers: true)
      csv_in = ::CSV.new(input_io, csv_opts)
      csv_out = ::CSV.new(output_io)
      allHeaders = new_headers.merge!(address_headers)
      postcode_client = SeOpenData::RDF::OsPostcodeUnit::Client.new(postcodeunit_cache)
      global_postcode_client = SeOpenData::RDF::OsPostcodeGlobalUnit::Client.new(global_postcode_cache,geocoder_standard)
      #add global postcode
      headers = nil
      row_count = csv_in.count
      csv_in.rewind
      prog_ctr = SeOpenData::Utils::ProgressCounter.new("Fetching geodata... ", row_count,$stderr)
      csv_in.each do |row|        
        unless headers
          headers = row.headers + new_headers.values.reject {|h| row.headers.include? h }
          csv_out << headers
        end
        prog_ctr.step
        # Only run if matches uk postcodes
        postcode = row[input_csv_postcode_header]
        country = row[input_country_header]
        #if uk_postcode?(postcode)
        if uk_postcode?(postcode)#TODO NEED TO REMOVE FOR GLOBAL GEO LOCATOR
          pcunit = postcode_client.get(postcode)
          loc_data = {
            geocontainer: pcunit ? pcunit[:within] : nil,
            geocontainer_lat: pcunit ? pcunit[:lat] : nil,
            geocontainer_lon: pcunit ? pcunit[:lng] : nil
          }
          new_headers.each {|k, v|
              row[v] = loc_data[k]
          }
        else #geocode using global geocoder
          
          #standardize the address if indicated
          headersToUse = {}
          if replace_address
            headersToUse = allHeaders
          else
            headersToUse = new_headers
          end
          #need to match standard h
          address = []

          address_headers.each {|k,v|
            address.push(row[v])
          }
          #return with the headers i want to replace
          pcunit = global_postcode_client.get(address,country) #assigns both address_headers field

          if pcunit == nil
            next
          end

          headersToUse.each { |k, v|
              row[v] = pcunit[geocoder_headers[k]]
          }

        end
        csv_out << row
      end

      global_postcode_client.finalize(0)
    end
  end
end
