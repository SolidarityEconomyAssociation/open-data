module SeOpenData
  module CSV
    module Standard
      module LocationIQStandard
        require "opencage/geocoder"

        Limit = 11000

        #map standard headers to geocoder headers
        Headers = {
          street_address: "road",
          locality: "city",
          region: "state",
          postcode: "postcode",
          country_name: "country",
          geocontainer_lat: "lat",
          geocontainer_lon: "lng",
          geocontainer: "geo_uri",
        }

        API_Key = File.read("../../APIs/locationIQAPI.txt") #load this securely

        class Geocoder
          def initialize
            # Headers here should relate to the headers in standard
            @requests_made = 0
          end

          def make_geo_container(lat, long)
            "https://www.openstreetmap.org/?mlat=#{lat}&mlon=#{long}"
          end

          #standard way of getting new data
          def get_new_data(search_key, country)
            #make sure we are within limits
            if @requests_made > Limit
              raise "400 too many requests (raised from localhost)"
            end
            #check search key length
            #remove elements to cut it down to size
            while search_key.length > 130
              temp = search_key.split(",")
              temp.pop
              search_key = temp.join(",")
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
            url = "https://eu1.locationiq.com/v1/search.php?key=#{API_Key}&q=#{search_key}&format=json&addressdetails=1&matchquality=1&limit=1"
            results = HTTParty.get(url)

            #if no results
            if results.length < 1
              return {}
            end

            res_raw = JSON.parse(results[0].to_s)

            #for those that don't replace with empty
            res = res_raw
              .merge(res_raw["address"])

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
            res.merge!({ "geo_uri" => make_geo_container(res["lat"], res["lng"]) })
            $stderr.puts res
            @requests_made += 1

            return res
          end
        end
      end
    end
  end
end
