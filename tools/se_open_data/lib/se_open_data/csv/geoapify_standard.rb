# coding: utf-8
module SeOpenData
  module CSV
    module Standard
      module GeoapifyStandard
        require "csv"
        require "httparty"
        require "json"
        require "cgi"
        require "se_open_data"

        Limit = 11000

        #map standard headers to geocoder headers
        Headers = {
          street_address: "street",
          locality: "city",
          region: "state",
          postcode: "postcode",
          country_name: "country",
          geocontainer_lat: "lat",
          geocontainer_lon: "lon",
          geocontainer: "geo_uri",
        }

        Country_Codes = { "Afghanistan" => "AF",
                          "Albania" => "AL",
                          "Algeria" => "DZ",
                          "American Samoa" => "AS",
                          "Andorra" => "AD",
                          "Angola" => "AO",
                          "Anguilla" => "AI",
                          "Antarctica" => "AQ",
                          "Antigua and Barbuda" => "AG",
                          "Argentina" => "AR",
                          "Armenia" => "AM",
                          "Aruba" => "AW",
                          "Australia" => "AU",
                          "Austria" => "AT",
                          "Azerbaijan" => "AZ",
                          "Bahamas" => "BS",
                          "Bahrain" => "BH",
                          "Bangladesh" => "BD",
                          "Barbados" => "BB",
                          "Belarus" => "BY",
                          "Belgium" => "BE",
                          "Belize" => "BZ",
                          "Benin" => "BJ",
                          "Bermuda" => "BM",
                          "Bhutan" => "BT",
                          "Bolivia, Plurinational State of" => "BO",
                          "Bonaire, Sint Eustatius and Saba" => "BQ",
                          "Bosnia and Herzegovina" => "BA",
                          "Botswana" => "BW",
                          "Bouvet Island" => "BV",
                          "Brazil" => "BR",
                          "British Indian Ocean Territory" => "IO",
                          "Brunei Darussalam" => "BN",
                          "Bulgaria" => "BG",
                          "Burkina Faso" => "BF",
                          "Burundi" => "BI",
                          "Cambodia" => "KH",
                          "Cameroon" => "CM",
                          "Canada" => "CA",
                          "Cape Verde" => "CV",
                          "Cayman Islands" => "KY",
                          "Central African Republic" => "CF",
                          "Chad" => "TD",
                          "Chile" => "CL",
                          "China" => "CN",
                          "Christmas Island" => "CX",
                          "Cocos (Keeling) Islands" => "CC",
                          "Colombia" => "CO",
                          "Comoros" => "KM",
                          "Congo" => "CG",
                          "Congo, the Democratic Republic of the" => "CD",
                          "Cook Islands" => "CK",
                          "Costa Rica" => "CR",
                          "Country name" => "Code",
                          "Croatia" => "HR",
                          "Cuba" => "CU",
                          "Curaçao" => "CW",
                          "Cyprus" => "CY",
                          "Czech Republic" => "CZ",
                          "Côte d'Ivoire": "CI",
                          "Denmark" => "DK",
                          "Djibouti" => "DJ",
                          "Dominica" => "DM",
                          "Dominican Republic" => "DO",
                          "Ecuador" => "EC",
                          "Egypt" => "EG",
                          "El Salvador" => "SV",
                          "Equatorial Guinea" => "GQ",
                          "Eritrea" => "ER",
                          "Estonia" => "EE",
                          "Ethiopia" => "ET",
                          "Falkland Islands (Malvinas)" => "FK",
                          "Faroe Islands" => "FO",
                          "Fiji" => "FJ",
                          "Finland" => "FI",
                          "France" => "FR",
                          "French Guiana" => "GF",
                          "French Polynesia" => "PF",
                          "French Southern Territories" => "TF",
                          "Gabon" => "GA",
                          "Gambia" => "GM",
                          "Georgia" => "GE",
                          "Germany" => "DE",
                          "Ghana" => "GH",
                          "Gibraltar" => "GI",
                          "Greece" => "GR",
                          "Greenland" => "GL",
                          "Grenada" => "GD",
                          "Guadeloupe" => "GP",
                          "Guam" => "GU",
                          "Guatemala" => "GT",
                          "Guernsey" => "GG",
                          "Guinea" => "GN",
                          "Guinea-Bissau" => "GW",
                          "Guyana" => "GY",
                          "Haiti" => "HT",
                          "Heard Island and McDonald Islands" => "HM",
                          "Holy See (Vatican City State)" => "VA",
                          "Honduras" => "HN",
                          "Hong Kong" => "HK",
                          "Hungary" => "HU",
                          "ISO 3166-2:GB" => "(.uk)",
                          "Iceland" => "IS",
                          "India" => "IN",
                          "Indonesia" => "ID",
                          "Iran, Islamic Republic of" => "IR",
                          "Iraq" => "IQ",
                          "Ireland" => "IE",
                          "Isle of Man" => "IM",
                          "Israel" => "IL",
                          "Italy" => "IT",
                          "Jamaica" => "JM",
                          "Japan" => "JP",
                          "Jersey" => "JE",
                          "Jordan" => "JO",
                          "Kazakhstan" => "KZ",
                          "Kenya" => "KE",
                          "Kiribati" => "KI",
                          "Korea, Democratic People's Republic of": "KP",
                          "Korea, Republic of" => "KR",
                          "Kuwait" => "KW",
                          "Kyrgyzstan" => "KG",
                          "Lao People's Democratic Republic": "LA",
                          "Latvia" => "LV",
                          "Lebanon" => "LB",
                          "Lesotho" => "LS",
                          "Liberia" => "LR",
                          "Libya" => "LY",
                          "Liechtenstein" => "LI",
                          "Lithuania" => "LT",
                          "Luxembourg" => "LU",
                          "Macao" => "MO",
                          "Macedonia, the former Yugoslav Republic of" => "MK",
                          "Madagascar" => "MG",
                          "Malawi" => "MW",
                          "Malaysia" => "MY",
                          "Maldives" => "MV",
                          "Mali" => "ML",
                          "Malta" => "MT",
                          "Marshall Islands" => "MH",
                          "Martinique" => "MQ",
                          "Mauritania" => "MR",
                          "Mauritius" => "MU",
                          "Mayotte" => "YT",
                          "Mexico" => "MX",
                          "Micronesia, Federated States of" => "FM",
                          "Moldova, Republic of" => "MD",
                          "Monaco" => "MC",
                          "Mongolia" => "MN",
                          "Montenegro" => "ME",
                          "Montserrat" => "MS",
                          "Morocco" => "MA",
                          "Mozambique" => "MZ",
                          "Myanmar" => "MM",
                          "Namibia" => "NA",
                          "Nauru" => "NR",
                          "Nepal" => "NP",
                          "Netherlands" => "NL",
                          "New Caledonia" => "NC",
                          "New Zealand" => "NZ",
                          "Nicaragua" => "NI",
                          "Niger" => "NE",
                          "Nigeria" => "NG",
                          "Niue" => "NU",
                          "Norfolk Island" => "NF",
                          "Northern Mariana Islands" => "MP",
                          "Norway" => "NO",
                          "Oman" => "OM",
                          "Pakistan" => "PK",
                          "Palau" => "PW",
                          "Palestine, State of" => "PS",
                          "Panama" => "PA",
                          "Papua New Guinea" => "PG",
                          "Paraguay" => "PY",
                          "Peru" => "PE",
                          "Philippines" => "PH",
                          "Pitcairn" => "PN",
                          "Poland" => "PL",
                          "Portugal" => "PT",
                          "Puerto Rico" => "PR",
                          "Qatar" => "QA",
                          "Romania" => "RO",
                          "Russian Federation" => "RU",
                          "Rwanda" => "RW",
                          "Réunion" => "RE",
                          "Saint Barthélemy" => "BL",
                          "Saint Helena, Ascension and Tristan da Cunha" => "SH",
                          "Saint Kitts and Nevis" => "KN",
                          "Saint Lucia" => "LC",
                          "Saint Martin (French part)" => "MF",
                          "Saint Pierre and Miquelon" => "PM",
                          "Saint Vincent and the Grenadines" => "VC",
                          "Samoa" => "WS",
                          "San Marino" => "SM",
                          "Sao Tome and Principe" => "ST",
                          "Saudi Arabia" => "SA",
                          "Senegal" => "SN",
                          "Serbia" => "RS",
                          "Seychelles" => "SC",
                          "Sierra Leone" => "SL",
                          "Singapore" => "SG",
                          "Sint Maarten (Dutch part)" => "SX",
                          "Slovakia" => "SK",
                          "Slovenia" => "SI",
                          "Solomon Islands" => "SB",
                          "Somalia" => "SO",
                          "South Africa" => "ZA",
                          "South Georgia and the South Sandwich Islands" => "GS",
                          "South Sudan" => "SS",
                          "Spain" => "ES",
                          "Sri Lanka" => "LK",
                          "Sudan" => "SD",
                          "Suriname" => "SR",
                          "Svalbard and Jan Mayen" => "SJ",
                          "Swaziland" => "SZ",
                          "Sweden" => "SE",
                          "Switzerland" => "CH",
                          "Syrian Arab Republic" => "SY",
                          "Taiwan, Province of China" => "TW",
                          "Tajikistan" => "TJ",
                          "Tanzania, United Republic of" => "TZ",
                          "Thailand" => "TH",
                          "Timor-Leste" => "TL",
                          "Togo" => "TG",
                          "Tokelau" => "TK",
                          "Tonga" => "TO",
                          "Trinidad and Tobago" => "TT",
                          "Tunisia" => "TN",
                          "Turkey" => "TR",
                          "Turkmenistan" => "TM",
                          "Turks and Caicos Islands" => "TC",
                          "Tuvalu" => "TV",
                          "Uganda" => "UG",
                          "Ukraine" => "UA",
                          "United Arab Emirates" => "AE",
                          "United Kingdom" => "GB",
                          "United States" => "US",
                          "United States Minor Outlying Islands" => "UM",
                          "Uruguay" => "UY",
                          "Uzbekistan" => "UZ",
                          "Vanuatu" => "VU",
                          "Venezuela, Bolivarian Republic of" => "VE",
                          "Viet Nam" => "VN",
                          "Virgin Islands, British" => "VG",
                          "Virgin Islands, U.S." => "VI",
                          "Wallis and Futuna" => "WF",
                          "Western Sahara" => "EH",
                          "Yemen" => "YE",
                          "Zambia" => "ZM",
                          "Zimbabwe" => "ZW",
                          "Åland Islands" => "AX" }

        class Geocoder
          # @param api_key [String] the API key.
          def initialize(api_key)
            @api_key = api_key
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
            uri_search_key = CGI.escape(search_key)
            url = "https://api.geoapify.com/v1/geocode/search?text=#{uri_search_key}&limit=1&apiKey=#{@api_key}"
            if (Country_Codes.has_key? country)
              cn = Country_Codes[country].downcase
              url = "https://api.geoapify.com/v1/geocode/search?text=#{uri_search_key}&&filter=countrycode:#{cn}&limit=1&apiKey=#{@api_key}"
            end
            results = HTTParty.get(url)
            res_raw_json = JSON.parse(results.to_s)["features"]
            res_raw = (res_raw_json == nil || res_raw_json.length < 1) ? {} : res_raw_json[0]["properties"]

            #if no results
            if res_raw == nil || res_raw == {}
              return {}
            end
            res = res_raw
            #check if address headers exist + house number which is used below but not in the headers list
            all_headers = Headers.merge("k" => "house_number")
            all_headers.each { |k, v|
              #if the header doesn't exist create an empty one
              if !res.key?(v)
                res.merge!({ v => "" })
              end
            }
            #add road and house number (save to road) to make a sensible address
            res["street"] = res["street"] + " " + res["house_number"].to_s unless res["house_number"].to_s == ""
            res.merge!({ "geo_uri" => make_geo_container(res["lat"], res["lon"]) })
            @requests_made += 1
            return res
          end

          def gen_geo_report(cached_entries_file, confidence_level = 0.25, gen_dir, generated_standard_file, headers_to_not_print)
            return unless File.exist?(cached_entries_file)

            # read in entries
            entries_raw = File.read(cached_entries_file)
            # is a map {key: properties}
            entries_json = JSON.load entries_raw

            # document initiatives that cannot be located (identified by)
            # does not have rank key
            no_entries_map = entries_json.select { |e, v| !v.has_key?("rank") }
            no_entries_array = []
            no_entries_headers = nil

            # then document the initiatives where the confidence level is below the passed confidence_level
            # identified by rank: {...,confidence:x,...} if rank exists
            low_confidence_map = entries_json.reject { |e, v| !v.has_key?("rank") }
              .select { |e, v| v["rank"]["confidence"] < confidence_level }
            low_confidence_array = []
            low_confidence_headers = nil

            # load standard file entries into map
            # match both maps to their entries
            client = SeOpenData::RDF::OsPostcodeGlobalUnit::Client
            addr_headers = Headers.keys.map { |a| SeOpenData::CSV::Standard::V1::Headers[a] }

            ::CSV.foreach(generated_standard_file, { headers: true }) do |row|
              # make this with row
              addr_array = []
              addr_headers.each { |header| addr_array.push(row[header]) if row.has_key? header }
              address = client.clean_and_build_address(addr_array)
              if no_entries_map.has_key? address
                no_entries_array.push row
                no_entries_headers = row.headers.reject { |h| headers_to_not_print.include?(h) } unless no_entries_headers
              elsif low_confidence_map.has_key? address
                row["confidence"] = low_confidence_map[address]["rank"]["confidence"]
                row["geocontainer_lat"] = low_confidence_map[address][Headers[:geocontainer_lat]]
                row["geocontainer_lon"] = low_confidence_map[address][Headers[:geocontainer_lon]]
                low_confidence_array.push row
                low_confidence_headers = row.headers.reject { |h| headers_to_not_print.include?(h) } unless low_confidence_headers
              end
            end

            # sort bad location
            low_confidence_array.sort! { |x, y| -(y["confidence"] <=> x["confidence"]) }

            no_location_file = gen_dir + "EntriesWithoutALocation.pdf"
            no_location_title = "Entries That Could Not be Geocoded"
            no_location_intro = "In this file we present the entries that could not be geocoded using the details described in each row.
            In total there are #{no_entries_array.length} entries without a location."

            bad_location_file = gen_dir + "LowConfidenceEntries.pdf"
            bad_location_title = "Entries That Are Geocoded With Low Confidence"
            bad_location_intro = "In this file we present the entries that are geocoded, but with a low confidence factor (below #{confidence_level}).
            In total there are #{low_confidence_array.length} entries which were geocoded with low confidence."

            # print documents
            verbose_fields = ["geocontainer_lat", "geocontainer_lon", "confidence"]
            doc = SeOpenData::Utils::ErrorDocumentGenerator.new("", "", "", "", [], false)
            doc.generate_document_from_row_array(no_location_title, no_location_intro,
                                                 no_location_file, no_entries_array, no_entries_headers)

            doc.generate_document_from_row_array(bad_location_title, bad_location_intro,
                                                 bad_location_file, low_confidence_array, low_confidence_headers, verbose_fields)

            # write bad-location entries to csv
            ::CSV.open(gen_dir + "bad_location.csv", "w") do |csv|
              csv << low_confidence_headers.reject { |h| headers_to_not_print.include?(h) }
              low_confidence_array.each { |r|
                rowarr = []
                low_confidence_headers.each { |h| rowarr.push(r[h]) if (!headers_to_not_print.include? h) }
                csv << rowarr
              }
            end

            # write no-location entries to csv
            ::CSV.open(gen_dir + "no_location.csv", "w") do |csv|
              csv << no_entries_headers.reject { |h| headers_to_not_print.include?(h) }
              no_entries_array.each { |r|
                rowarr = []
                no_entries_headers.each { |h| rowarr.push(r[h]) if (!headers_to_not_print.include? h) }
                csv << rowarr
              }
            end
          end
        end
      end
    end
  end
end
