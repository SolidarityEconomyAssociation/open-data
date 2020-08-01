module SeOpenData
  module CSV
    module Standard
      module GeoapifyStandard
        require "httparty"
        require "json"
        require "cgi"

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
          # @param api_key [String] the OpenCage API key.
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
        end
      end
    end
  end
end
