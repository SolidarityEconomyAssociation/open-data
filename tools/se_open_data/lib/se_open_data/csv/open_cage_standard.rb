module SeOpenData
  module CSV
    module Standard
      module OpenCageAddressStandard
        require "opencage/geocoder"

        Limit = 11000

        Headers = {
          street_address: "road",
          locality: "city",
          region: "state",
          postcode: "postcode",
          country_name: "country",
          geocontainer_lat: "lat",
          geocontainer_lon: "lng",
          geocontainer: "geo_uri"
        }

        StandardInputHeaderHeaderss = [
          :street_address,
          :locality,
          :region,
          :postcode,
          :country_name,
        ]

        Open_Cage_API_Key = File.read("../../APIs/OpenCageKey.txt") #load this securely

        class OpenCageClass
          def initialize
            # Headers here should relate to the headers in standard
            @geocoder = OpenCage::Geocoder.new(api_key: Open_Cage_API_Key)
            @requests_made = 0
          end

          def make_geo_container(lat,long)
            "https://www.openstreetmap.org/?mlat=#{lat}&mlon=#{long}"
          end

          #open cage standard way of getting new data
          def get_new_data(search_key, country)
            #make sure we are within limits
            if @requests_made > Limit
              raise "400 too many requests (raised from localhost)"
            end
            #check search key length
            #remove elements to cut it down to size
            while search_key.length > 130 do
              temp = search_key.split(",")
              temp.pop
              search_key = temp.join(',')
            end
            #return empty for unsensible key
            if search_key.length < 5
              return {}
            end

            #requests requirements
            #comma-separated
            #no names
            #include country
            #remove unneeded characters '/< etc..
            #remove unneeded address info
            results = @geocoder.geocode(search_key, country_code: country, no_annotations: 1, limit: 1)

            #if no results
            if results.length < 1
              return {}
            end

            res_raw = results.first.raw

            #for those that don't replace with empty
            res = res_raw["components"]
              .merge(res_raw["geometry"])
              .merge({ "formatted" => res_raw["formatted"] })

            #check if address headers exist + house number which is used below but not in the headers list
            all_headers = Headers.merge("k" => "house_number")
            all_headers.each { |k, v|
              #if the header doesn't exist create an empty one
              if !res.key?(v)
                res.merge!({ v => "" })
              end
            }
            #add road and house number (save to road) to make a sensible address
            res["road"] = res["road"] + " " + res["house_number"].to_s
            res.merge!({"geo_uri" => make_geo_container(res["lat"],res["lng"])})
            
            @requests_made += 1

            return res
          end
        end
      end
    end
  end
end
