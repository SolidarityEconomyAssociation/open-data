#!/bin/env ruby

# Generate DotCoop survey data.
#
# We need to combine DotCoop original.csv and standard.csv to get
# geolocations for organisations


require 'csv'
require 'uri'

unless original_csv_file = ARGV[0]
  warn "please supply the original.csv path";
  exit 1;
end
unless standard_csv_file = ARGV[1]
  warn "please supply the standard.csv path";
  exit 1;
end

def norm_id(id)
  id.downcase
    .gsub(/[\W]/, '')
    .gsub(/cooperative/i, 'coop')
    .gsub(/(limited|ltd)/i, '')
end


def read_csv(file, id_key:, org_key:)
  id_index = {}
  org_index = {}
  CSV.foreach(file, headers: true).map do |row|
    id = row[id_key]
    raise "duplicate key field #{id_key}: #{id}" if id_index.has_key? id_key

    org = norm_id row[org_key]
    id_index[id] = row
    org_index[org] = row
  end

  return {ids: id_index, orgs: org_index}
end

# Expecting these headers:
# Domain,RegistrantId,CreationDate,Organisation,StreetNumber,StreetName,StreetAddress,City,State,Country,PostCode,LastChanged
original = read_csv original_csv_file, id_key: 'Domain', org_key: 'Organisation'

# Expecting these headers:
# Identifier,Name,Description,Organisational Structure,Primary Activity,Activities,Street Address,Locality,Region,Postcode,Country ID,Territory ID,Website,Phone,Email,Twitter,Facebook,Companies House Number,Qualifiers,Membership Type,Latitude,Longitude,Geo Container,Geo Container Latitude,Geo Container Longitude
standard = read_csv standard_csv_file, id_key: 'Identifier', org_key: 'Name'

# This defines look-ups found manually for cases which aren't
# otherwise matched
specials = {
  'leganazionaledellecoopemutue' => norm_id('Lega Nazionale delle Cooperative e Mutue (LEGACOOP)'),
  'themidcountiescoop' => norm_id('Midcounties Cooperative'),
  'nationaldairydevelopmentboardnddb' => norm_id('National Dairy Development Board'),
  'sostrecivicsccl' => norm_id('SostreCivic'),
  'themiddletennesseeelectricmembershipcorporation' => norm_id('Middle Tennessee Electric Membership Corporation'),
}


joined = {}

# Output header order
headers = %w(ICAID RegistrantId Name Website Description Domains Address Location)

# Loop over the original.csv data rows, accumulating data, and
# cross-indexing with the standard.csv data to get accesss to location
# etc.  The latter has been de-duplicated using an algorithm not fully
# understood to the author of this script at the time of writing, so
# some heuristics are applied to match them up.
original[:ids].each do |domain, row|
  registrant_id = row['RegistrantId']
  original_id = registrant_id.sub('C','').sub('-CNIC','')
  original_org = norm_id row['Organisation']

  # Handle special cases
  if specials.has_key? original_org
    original_org = specials[original_org]
  end

  # Find the location and other data from standard.csv. We match using
  # the ID, if there is a match, otherwise using the organisation
  # name, normalised to make matches more likely.  (e.g. Cooperative,
  # Co-op and coop all normalise to coop, and other things like that)
  # Because orgs may have more than one reg id / domain, and the input
  # has one row per domain, whereas the output has one row per reg if,
  # there may be multiple rows in the output which share this data.
  standard_id = original_id
  unless standard[:ids].has_key? standard_id
#    warn "Missing match for #{registrant_id}: #{domain}\t#{row['Organisation']}"

    # Try matching by org name
    unless standard[:orgs].has_key? original_org
      warn "Unable to match id: #{registrant_id}"
      next
    end

    standard_id = standard[:orgs][original_org]['Identifier']
  end

  # Now join the data
  (registrant_id, name, description) = row.fields(*%w{RegistrantId Organisation Description})
  address = row.fields(*%w{StreetNumber StreetName StreetAddress City State Country PostCode})
              .map{|f| f&.strip} # strip whitespace
              .reject{|f| f == nil || f.size == 0 } # reject blanks
              .join("\n");
  standard_row = standard[:ids][standard_id]
  location = standard_row.fields('Geo Container Latitude', 'Geo Container Longitude')&.join(' ')
  if joined.has_key? registrant_id
    fields = joined[registrant_id]
    
    # Check for mismatches    
    warn "#{registrant_id} name mismatches: #{name} != #{fields['Name']}" if
      fields['Name'] != name
    warn "#{registrant_id} description mismatches: #{description} != #{fields['Description']}" if
      fields['Description'] != description
    warn "#{registrant_id} location mismatches: #{location} != #{fields['Location']}" if
      fields['Location'] != location
    warn "#{registrant_id} address mismatches: #{address} != #{fields['Address']}" if
      fields['Address'] != address

    fields['Domains'][domain] = 1
  else
    # Add a new row
    fields = joined[registrant_id] = CSV::Row.new(headers, [])

    fields['ICAID'] = nil

    # May be several RegistrantIds for one org, but this data is per
    # RegistrantId - later logic also assumes this field is a single
    # ID.
    fields['RegistrantId'] = registrant_id

    fields['Name'] = name
    
    %w(Website Description).each do |key|
      fields[key] = row[key]
    end

    fields['Location'] = location
    fields['Address'] = address
    fields['Domains'] = {domain => 1}
  end
end

# Now write out the data in order of name
count = 0
joined.keys.sort do |a,b|
  joined[a]['Name'].downcase <=> joined[b]['Name'].downcase
end.each do |key|
  puts headers.join(",") unless count > 0
  count += 1
  fields = joined[key]
  if fields['Domains'].is_a? Hash
    fields['Domains'] = fields['Domains'].keys.sort.join(";");
  end
  puts fields.to_csv
end
