#!/bin/env ruby
# coding: utf-8

# Generate DotCoop survey data.
#
# We need to clean up ICA standard.csv to get names, text
# descriptions, web URLs and geolocations for organisations.  In
# general we assume utf-8 encoding in CSV and other data.

require 'csv'
require 'nokogiri'

unless standard_csv_file = ARGV[0]
  warn "please supply the standard.csv path";
  exit 1;
end


def read_csv(file, id_key:)
  id_index = {}
  CSV.foreach(file, headers: true).map do |row|
    id = row[id_key]
    raise "duplicate key field #{id_key}: #{id}" if id_index.has_key? id_key

    id_index[id] = row
  end

  return id_index
end

def html_to_text(html)
  Nokogiri::HTML(html)
    .text
    .gsub(/[[:space:]&&[^\n]]/,' ') # normalise crazy non-linefeed whitespace to spaces
    .strip 
    .split("\n")
    .collect { |line| line.strip }
    .join("\n")
end

# Expecting these headers:
# Identifier,Name,Description,Organisational Structure,Primary Activity,Activities,Street Address,Locality,Region,Postcode,Country ID,Territory ID,Website,Phone,Email,Twitter,Facebook,Companies House Number,Qualifiers,Membership Type,Latitude,Longitude,Geo Container,Geo Container Latitude,Geo Container Longitude
standard = read_csv standard_csv_file, id_key: 'Identifier'

joined = {}

# Output header order
headers = %w(ICAID RegistrantId Name Website Description Domains Address Location)

# Loop over the standard.csv data rows, accumulating and cleaning data
standard.each do |domain, row|
  standard_id = row['Identifier']

  fields = joined[standard_id] = CSV::Row.new(headers, [])
  fields['ICAID'] = standard_id

  # May be several RegistrantIds for this org - if we knew them at
  # this point. However, we don't.  Later logic also assumes this
  # field is a single ID.
  fields['RegistrantId'] = nil 
  %w(Name Website).each do |key|
    fields[key] = row[key]
  end
  
  fields['Description'] = html_to_text row['Description']
  fields['Domains'] = nil # may be several - if we knew them at this point
  fields['Address'] = row.fields("Street Address","Locality","Region","Postcode","Country ID")
                        .map{|f| f&.strip} # strip whitespace
                        .reject{|f| f == nil || f.size == 0 } # reject blanks
                        .join("\n");
  location = row.fields('Latitude', 'Longitude')
  if location.compact.size < 2 || location == ["0", "0"]
    location = row.fields('Geo Container Latitude', 'Geo Container Longitude')
    if location.compact.size < 2 || location == ["0", "0"]
      location = nil
    end
  end
  fields['Location'] = location&.join(' ')   
end

def by_org_name(a,b)
  joined[a]['Name'] <=> joined[b]['Name']
end

# Now write out the data in order of name
count = 0
joined.keys.sort do |a,b|
  joined[a]['Name'].downcase <=> joined[b]['Name'].downcase
end.each do |key|
  puts headers.join(",") unless count > 0
  count += 1
  fields = joined[key]
  puts fields.to_csv
end
