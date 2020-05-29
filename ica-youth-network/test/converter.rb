# coding: utf-8


# This is the Converter for Co-ops UK 'outlets' CSV.
# It converts it into a CSV with standard column headings.
#
# See discussion here:
# https://github.com/SolidarityEconomyAssociation/open-data/issues/11
require 'se_open_data'
require 'csv'

# This is the CSV standard that we're converting into:
OutputStandard = SeOpenData::CSV::Standard::V1
EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
LAT_LNG_REGEX = /^\-?\d+\.{1}\d+$/i
TYPE_TO_ORG_STRUCT = {
  "Cooperativa de consumo / usuario final" => "Consumer co-operative",
  "Coop�rative de consommateur.rice.s"=> "Consumer co-operative",
  "Final consumer/user cooperative"=> "Consumer co-operative",
  "Cooperativa de m�ltiples actores"=> "Multi-stakeholder co-operative",
  "Coop�rative pluri-acteurs"=> "Multi-stakeholder co-operative",
  "Multi-stakeholder cooperative"=> "Multi-stakeholder co-operative",
  "Cooperativa de producci�n"=> "Producer co-operative",
  "Coop�rative de producteur.rice.s (dont agricole)"=> "Producer co-operative",
  "Producer cooperative"=> "Producer co-operative",
  "Cooperativa de trabajo y empleo"=> "Self-employed",
  "Cooperativa di lavoro"=> "Self-employed",
  "Work and employment cooperative"=> "Self-employed",
  "Coop�rative de travailleur.se.s"=> "Workers co-operative"
}



# Defines a schema mapping for ica-youth-network data.
#
# The hash {SpecializedCsvReader::InputHeaders} identifies methods which
# should be implemented as simple CSV field look-ups.
#
# Some are named in {OutputStandard}'s keys and so will be copied
# verbatim into the output CSV data. These have no underscore prefix.
#
# Those with underscore prefixes are used internally.
#
# The other keys of {OutputStandard} must also have methods
# implemented in this class. These are the ones which have more
# complicated transformation rules - they cannot be a simple copy of
# an existing data field.
#
# Input data fields are:
#
# - Organization Type
# - Name
# - name
# - Region
# - Country
# - City
# - Latitude
# - Longitude
# - Size
# - Type
# - Sector
# - Address
# - Description
# - Additional Details
# - Website
# - Email
#
class SpecializedCsvReader < SeOpenData::CSV::RowReader

  # These define methods (as keys) to implement as simple hash
  # look-ups using CSV field names (values).
  #
  InputHeaders = {
    id: "Id",
    # postcode: "PostCode",
    country_name: "Country",
    type: "Type",
    street_address: "Address",
    locality: "City",

    #registrar: "Registrar",
    #registered_number: "Registered Number"
    _desc: "Description",
    _additional_desc: "Additional Details",
    _mail: "Email",
    _name: "Name",
    _country: "Country",
    _website: "Website",
    _lt: "Latitude",
    _ln: "Longitude",
  }
  # MISSING!
  # primary_activity (name?)
  # activities
  # region (region?) 
  # postcode
  # phone
  # twitter
  # facebook
  # companies_house_number
  # geocontainer
  # geocontainer_lat
  # geocontainer_lon
  
  # @param row [Hash<String => String>] - a row of CSV data
  def initialize(row)
    # Let CSV::RowReader provide methods for accessing columns described by InputHeaders, above:
    super(row, InputHeaders)
  end


  def longitude
    if LAT_LNG_REGEX.match?(_ln)
      _ln
    else
      0.0
    end
  end
  
  def latitude
    if LAT_LNG_REGEX.match?(_lt)
      _lt
    else
      0.0
    end
  end

  def description
    [_desc, _additional_desc].compact.join("\\n\\n")
  end
  
  def email
    if _mail && !_mail.empty?
      e = EMAIL_REGEX.match?(_mail)
      if e
        return _mail
      else
        return ""
      end
      
    end

  end

  def homepage
    if _website && !_website.empty?
      http_regex = /https?\S+/
      m = http_regex.match(_website)
      if m
        m[0]
      else
        www_regex =  /^www\./
        www_m = www_regex.match(_website)
        if www_m
          "http://#{_website}"
        else
          add_comment("This doesn't look like a website: #{_website} (Maybe it's missing the http:// ?)")
          nil
        end
      end
    end
  end

  def name
    _name || "No Name"
  end

  def legal_forms
    # Return a list of strings, separated by OutputStandard::SubFieldSeparator.
    # Each item in the list is a prefLabel taken from essglobal/standard/legal-form.skos.
    # See lib/se_open_data/essglobal/legal_form.rb
    "Cooperative"
  end

  def organisational_structure
    ## Return a list of strings, separated by OutputStandard::SubFieldSeparator.
    ## Each item in the list is a prefLabel taken from essglobal/standard/legal-form.skos.
    ## See lib/se_open_data/essglobal/legal_form.rb
    org_st = TYPE_TO_ORG_STRUCT[type]? TYPE_TO_ORG_STRUCT[type] : "Co-operative"

    org_st
  end

  # Adds a new last column `Id` and inserts in it a numeric index in each row.
  #
  # @param input - an input stream, or the name of a file to read
  # @param output - an output stream, or the name of a file to read  
  def self.add_unique_ids(input:, output:)
    input = File.open(input) unless input.is_a? IO
    output = File.open(output, 'w') unless output.is_a? IO
    
    csv_opts = {}
    csv_opts.merge!(headers: true)

    csv_in = ::CSV.new(input, csv_opts)
    csv_out = ::CSV.new(output)
    headers = nil
    i = 0
    csv_in.each do |row|
      unless headers
        headers = row.headers
        headers.push("Id")
        csv_out << headers
      end
      row['Id'] = i
      i+=1
      csv_out << row
    end

  ensure
    input.close
    output.close
  end

  
  # Transforms the rows from Co-ops UK schema to our standard
  #
  # @param input - an input stream, or the name of a file to read
  # @param output - an output stream, or the name of a file to read
  def self.convert(input:, output:)
    input = File.open(input) unless input.is_a? IO
    output = File.open(output, 'w') unless output.is_a? IO
    
    # Note the use of #read, convert expects a string so it can remove
    # BOMs. Possibly not required if the csv has already been cleaned
    # up?
    SeOpenData::CSV.convert(
      output, OutputStandard::Headers,
      input.read, SpecializedCsvReader, {}
    )
  ensure
    input.close
    output.close
  end
end

