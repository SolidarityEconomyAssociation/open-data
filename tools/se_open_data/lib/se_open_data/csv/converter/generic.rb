require 'se_open_data'
require 'se_open_data/config'
require 'se_open_data/csv/add_postcode_lat_long'
require 'se_open_data/csv/schema'
require 'csv'

module SeOpenData
  module CSV
    module Converter
      # Converts generic SSE initiative data
      #
      # This needs to be a schema derived from FIXME
      #
      module Generic
        OutputStandard = SeOpenData::CSV::Standard::V1 # FIXME remove
        
        # This creates a generic converter for mapping incoming data
        # with the specified incoming schema into the standard schema.
        #
        # The incoming schema must have fields and primary keys matching FIXME
        #
        # The case-specific logic that maps the input field data is
        # defined in the do-block. It will be wrapped in a loop which
        # reads the input file and writes the output file. See the
        # documentation for {SeOpenData::CSV::Schema.converter}.
        #
        # The response data downloaded from limesurvey via the API appears
        # to be different to that downloaded previously.
        # - semi-colon delimited, not comma delimited
        # - 'activities' field contains a identifier, not a human-readable phrase.
        #
        # The delimiter appears to be configurable in the web download, but not in the API.
        # https://bugs.limesurvey.org/view.php?id=13747
        def self.mk_converter(from_schema:,
                              to_schema: SeOpenData::CSV::Schemas::Versions[0],
                              input_csv_opts: {col_sep: ';', skip_blanks: true})
          return SeOpenData::CSV::Schema.converter(
                   from_schema: from_schema,
                   to_schema: to_schema,
                   input_csv_opts: input_csv_opts
                 ) do | # These parameters match source schema field ids
                        id:,
                        name:,
                        address_a:,
                        address_b:,
                        address_c:,
                        address_d:,
                        address_e:,
                        address_a1:,
                        location:,
                        email:,
                        phone:,
                        website:,
                        facebook:,
                        twitter:,
                        description:,
                        activity:,
                        approved:,
                        structure_SQ001:,
                        structure_SQ002:,
                        structure_SQ003:,
                        structure_SQ004:,
                        structure_SQ005:,
                        structure_SQ006:,
                        structure_SQ007:,
                        structure_SQ008:,
                        structure_SQ009:,
                        structure_SQ010:,
                        structure_SQ011:,
                        structure_SQ012:,
                        secondaryActivities_SQ002:,
                        secondaryActivities_SQ003:,
                        secondaryActivities_SQ004:,
                        secondaryActivities_SQ005:,
                        secondaryActivities_SQ006:,
                        secondaryActivities_SQ007:,
                        secondaryActivities_SQ008:,
                        secondaryActivities_SQ009:,
                        secondaryActivities_SQ010:,
                        secondaryActivities_SQ011:,
                        secondaryActivities_SQ012:,
                        secondaryActivities_SQ013:,
                        **rest
                        |
                        # A mapping to the target schema field ids

                        # Don't import this initiative if it isn't approved
                        next unless approved&.downcase == 'yes'

                        # Define some aliases
                        arts = secondaryActivities_SQ002
                        campaigning = secondaryActivities_SQ003
                        community = secondaryActivities_SQ004
                        education = secondaryActivities_SQ005
                        energy = secondaryActivities_SQ006
                        food = secondaryActivities_SQ007
                        goods_services = secondaryActivities_SQ008
                        health = secondaryActivities_SQ009
                        housing = secondaryActivities_SQ010
                        money = secondaryActivities_SQ011
                        nature = secondaryActivities_SQ012
                        reuse = secondaryActivities_SQ013
                        
                        community_group = structure_SQ001
                        non_profit = structure_SQ002
                        social_enterprise = structure_SQ003
                        charity = structure_SQ004
                        company = structure_SQ005
                        workers_coop = structure_SQ006
                        housing_coop = structure_SQ007
                        consumer_coop = structure_SQ008
                        producer_coop = structure_SQ009
                        stakeholder_coop = structure_SQ010
                        community_interest_company = structure_SQ011
                        community_benefit_society = structure_SQ012

                        (latitude, longitude) = [*location.to_s.split(';'), '', ''].collect &:strip
                        {
                          id: id,
                          name: name,
                          description: description,
                          organisational_structure: [
                            ## Return a list of strings, separated by OutputStandard::SubFieldSeparator.
                            ## Each item in the list is a prefLabel taken from essglobal/standard/legal-form.skos.
                            ## See lib/se_open_data/essglobal/legal_form.rb
                            community_group == "Y" ? "Community group (formal or informal)" : nil,
                            non_profit == "Y" ? "Not-for-profit organisation" : nil,
                            social_enterprise == "Y" ? "Social enterprise" : nil,
                            charity == "Y" ? "Charity" : nil,
                            company == "Y" ? "Company (Other)" : nil,
                            workers_coop == "Y" ? "Workers co-operative" : nil,
                            housing_coop == "Y" ? "Housing co-operative" : nil,
                            consumer_coop == "Y" ? "Consumer co-operative" : nil,
                            producer_coop == "Y" ? "Producer co-operative" : nil,
                            stakeholder_coop == "Y" ? "Multi-stakeholder co-operative" : nil,
                            community_interest_company == "Y" ? "Community Interest Company (CIC)" : nil,
                            community_benefit_society == "Y" ? "Community Benefit Society / Industrial and Provident Society (IPS)" : nil
                          ].compact.join(OutputStandard::SubFieldSeparator),
                          primary_activity: {
                            'SQ001' => 'Arts, Media, Culture & Leisure',
                            'SQ002' => 'Campaigning, Activism & Advocacy',
                            'SQ003' => 'Community & Collective Spaces',
                            'SQ004' => 'Education',
                            'SQ005' => 'Energy',
                            'SQ006' => 'Food',
                            'SQ007' => 'Goods & Services',
                            'SQ008' => 'Health, Social Care & Wellbeing',
                            'SQ009' => 'Housing',
                            'SQ010' => 'Money & Finance',
                            'SQ011' => 'Nature, Conservation & Environment',
                            'SQ012' => 'Reduce, Reuse, Repair & Recycle',
                          }[activity] || '',
                          activities:  [
                            arts == "Y" ? "Arts, Media, Culture & Leisure" : nil,
                            campaigning == "Y" ? "Campaigning, Activism & Advocacy" : nil,
                            community == "Y" ? "Community & Collective Spaces" : nil,
                            education == "Y" ? "Education" : nil,
                            energy == "Y" ? "Energy" : nil,
                            food == "Y" ? "Food" : nil,
                            goods_services == "Y" ? "Goods & Services" : nil,
                            health == "Y" ? "Health, Social Care & Wellbeing" : nil,
                            housing == "Y" ? "Housing" : nil,
                            money == "Y" ? "Money & Finance" : nil,
                            nature == "Y" ? "Nature, Conservation & Environment" : nil,
                            reuse == "Y" ? "Reduce, Reuse, Repair & Recycle" : nil
                          ].compact.join(OutputStandard::SubFieldSeparator),
                          street_address: [
                            !address_a.empty? ? address_a : nil,
                            !address_b.empty? ? address_b : nil,
                            !address_c.empty? ? address_c : nil
                          ].compact.join(OutputStandard::SubFieldSeparator),
                          locality: address_d,
                          region: '',
                          postcode: address_e.to_s.upcase,
                          country_name: '',
                          homepage: normalise_url(website),
                          phone: normalise_phone_number(phone),
                          email: email,
                          twitter: normalise_twitter_handle(twitter),
                          facebook: normalise_facebook_account(facebook),
                          companies_house_number: '',
                          latitude: latitude,
                          longitude: longitude,
                          geocontainer: '',
                          geocontainer_lat: '',
                          geocontainer_lon: '',
                        }
          end
        end
                        
        # Entry point if invoked as a script.
        #
        # Expects a {SeOpenData::Config} object as the parameter, to
        # define the locations of various resources, and set options on
        # the conversion process.
        def self.convert(config)

          # original src csv file
          original_csv = File.join(config.SRC_CSV_DIR, config.ORIGINAL_CSV)

          # Intermediate csv files
          initial_pass = File.join(config.GEN_CSV_DIR, "initiatives.csv")

          # Output csv file
          output_csv = config.STANDARD_CSV

          # Get the Geoapify API key
          pass = SeOpenData::Utils::PasswordStore.new(use_env_vars: config.USE_ENV_PASSWORDS)
          api_key = pass.get config.GEOCODER_API_KEY_PATH

          # Create a csv converter
          schema = SeOpenData::CSV::Schema.load_file(config.ORIGINAL_CSV_SCHEMA)
          converter = mk_converter(from_schema: schema)
          
          # generate the cleared error file # FIXME remove if not needed
          # SeOpenData::CSV.clean_up in_f: csv_to_standard, out_f: cleared_errors
          
          # Transforms the rows from Co-ops UK schema to our standard
          # Note the BOM and encoding flags, which avoid a MalformedCSVError
          converter.convert File.open(original_csv, "r:bom|utf-8"), initial_pass
          add_postcode_lat_long(infile: initial_pass, outfile: output_csv,
                                api_key: api_key, lat_lng_cache: config.POSTCODE_LAT_LNG_CACHE,
                                postcode_global_cache: config.GEODATA_CACHE)
        rescue => e
          raise "error transforming #{original_csv} into #{output_csv}: #{e.message}"
        end

        private


        def self.subhash(hash, *keys)
          keys = keys.select { |k| hash.key?(k) }
          Hash[keys.zip(hash.values_at(*keys))]
        end

        def self.normalise_phone_number(val)
          val
            .to_s
            .delete("() ")
            .sub(/^\+?44/, "0")
            .sub(/^00/, "0")
            .gsub(/[^\d]/, "")
        end

        def self.normalise_twitter_handle(val)
          val
            .downcase
            .sub(/h?t?t?p?s?:?\/?\/?w?w?w?\.?twitter\.com\//, "")
            .delete("@#/")
        end

        def self.normalise_facebook_account(val)
          val
            .downcase
            .sub(/h?t?t?p?s?:?\/?\/?w?w?w?\.?facebook\.com\//, "")
            .sub(/h?t?t?p?s?:?\/?\/?w?w?w?\.?fb\.com\//, "")
            .delete("@#/")
        end


        def self.normalise_url(website)
          if website && !website.empty? && website != "N/A"
            http_regex = /https?\S+/
            m = http_regex.match(website)
            if m
              m[0]
            else
              www_regex =  /^www\./
              www_m = www_regex.match(website)
              if www_m
                "http://#{website}"
              else
                add_comment("This doesn't look like a website: #{website} (Maybe it's missing the http:// ?)")
                nil
              end
            end
          end
        end

        def self.add_comment(txt)
          warn txt
        end

        def self.add_postcode_lat_long(infile:, outfile:, api_key:, lat_lng_cache:,
                                       postcode_global_cache:)
          input = File.open(infile, "r:bom|utf-8")
          output = File.open(outfile, "w")
          
          # Geoapify API key required
          
          geocoder = SeOpenData::CSV::Standard::GeoapifyStandard::Geocoder.new(api_key)
          geocoder_headers = SeOpenData::CSV::Standard::GeoapifyStandard::Headers
          SeOpenData::CSV._add_postcode_lat_long(
            input,
            output,
            OutputStandard::Headers[:postcode],
            OutputStandard::Headers[:country_name],
            subhash(OutputStandard::Headers,
                    :geocontainer,
                    :geocontainer_lat,
                    :geocontainer_lon),
            lat_lng_cache,
            {},
            postcode_global_cache,
            subhash(OutputStandard::Headers,
                    :street_address,
                    :locality,
                    :region,
                    :postcode,
                    :country_name),
            true,
            geocoder_headers,
            geocoder,
            true
          )
        ensure
          input.close
          output.close
        end
      end
    end
  end
end
