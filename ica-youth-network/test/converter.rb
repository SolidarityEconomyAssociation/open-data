

# This is the Converter for Co-ops UK 'outlets' CSV.
# It converts it into a CSV with standard column headings.
$LOAD_PATH.unshift '/Volumes/Extra/SEA-dev/open-data-and-maps/data/tools/se_open_data/lib'
require 'se_open_data'

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



class SpecializedCsvReader < SeOpenData::CSV::RowReader
  # Headers in input CSV (with Hash key symbols matching Hash key symbols in output CSV Headers)
  InputHeaders = {
    # These symbols match symbols in OutputStandard::Headers.
    # So the corresponding cells with be copied from input to output:
    name: "",
    # postcode: "PostCode",
    country_name: "Country",
    organisational_structure: "",
    type:"Type",
    description: "",
    desc: "Description",
    additional_desc: "Additional Details",

    # These symbols don't match symbols in OutputStandard::Headers,
    # but CSV::RowReader creates a method using these symbol names to
    # read that column from the row:
    
    #registrar: "Registrar",
    #registered_number: "Registered Number"
    mail:"Email",
    tempName: "Name",
    street_address: "Address",
    locality: "City",
    country: "Country",
    homepage: "",
    website: "Website",
    id: "Id",
    lt:"Latitude",
    ln:"Longitude",
    longitude: "",
    latitude: "",
    email:""
  }

  def initialize(row)
    # Let CSV::RowReader provide methods for accessing columns described by InputHeaders, above:
    super(row, InputHeaders)
  end
  # Some columns in the output are not simple copies of input columns:
  # Here are the methods for generating those output columns:
  # (So all method names below should aldo appear as keys in the output_headers Hash)
  # def id
  #   raise(SeOpenData::Exception::IgnoreCsvRow, "\"Domain\" column is empty") unless domain
  #   domain.sub(/\.coop$/, "")
  # end

  def longitude
    if LAT_LNG_REGEX.match?(ln)
      ln
    else
      0.0
    end
  end
  def latitude
    if LAT_LNG_REGEX.match?(lt)
      lt
    else
      0.0
    end
  end

  def description
    
    descript = ""
    if desc
      descript += desc
    end
    if additional_desc
      descript += additional_desc
    end

  end
  
  def email
    if mail && !mail.empty?
      e = EMAIL_REGEX.match?(mail)
      if e
        return mail
      else
        return ""
      end
      
    end

  end

  def homepage
    if website && !website.empty?
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

  def name
    if(tempName)
      tempName
    else
      "No Name"
    end
  end

  def legal_forms
    # Return a list of strings, separated by OutputStandard::SubFieldSeparator.
    # Each item in the list is a prefLabel taken from essglobal/standard/legal-form.skos.
    # See lib/se_open_data/essglobal/legal_form.rb
    [
      "Coopecountry_namerative"
    ].compact.join(OutputStandard::SubFieldSeparator)
  end

  def organisational_structure
    ## Return a list of strings, separated by OutputStandard::SubFieldSeparator.
    ## Each item in the list is a prefLabel taken from essglobal/standard/legal-form.skos.
    ## See lib/se_open_data/essglobal/legal_form.rb
    org_st = TYPE_TO_ORG_STRUCT[type]? TYPE_TO_ORG_STRUCT[type] : "Co-operative"

    [
      org_st
    ].compact.join(OutputStandard::SubFieldSeparator)
  end
  
end


SeOpenData::CSV.convert(
  # Output:
  $stdout, OutputStandard::Headers,
  # Input:
  # ARGF.read, SpecializedCsvReader, encoding: "UTF-8"
  ARGF.read, SpecializedCsvReader, {}
  # inputContent, SpecializedCsvReader, {}
)

