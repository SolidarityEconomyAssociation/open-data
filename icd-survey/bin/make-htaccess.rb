#!/bin/env ruby

# This generates a .htaccess file with redirect rules for each
# prefilled survey URL and it's short version.  The default case just
# directs to the form with no prefill

require 'csv'
require 'uri'

unless input_csv_file = ARGV[0]
  warn "please supply a filename";
  exit 1;
end

def enc(str)
  return URI.encode_www_form_component(str).gsub(/[+]/, '%20')
end


fields = {
  'Name' => 'org/name',
  'Description' => 'org/description',
  'Location' => 'org/geoloc',
  'Website' => 'org/url',
  'RegistrantId' => 'org/dotcoopid',
  'ICAID' => 'org/icanum',
}


to_url_stem = "https://ee.kobotoolbox.org/single/4yjwMLxU" # Tom's draft
#to_url_stem = 'https://ee.kobotoolbox.org/single/uZ7QPGoM'


# Print the config to stdout for a .htacccess file
# From https://serverfault.com/a/414245/421755
puts <<HERE
Options -MultiViews +FollowSymLinks
RewriteEngine On
HERE

CSV.foreach(input_csv_file, headers: true) do |row|
  params = fields.keys.map do |field|
    "d[#{fields[field]}]=#{enc(row[field]).gsub(/%/, '\\%')}"
  end
  if row['ICAID'].nil?
    from_path = "dotcoop/#{row['RegistrantId']}"
  else
    from_path = "ica/#{row['ICAID']}"
  end
  
  to_url = "#{to_url_stem}?#{params.join('&')}"  
  puts "RewriteRule #{from_path} #{to_url} [NE,R,L]"
end

# Default redirect for no ID
puts "RewriteRule ^(ica|dotcoop)/.* #{to_url_stem} [NE,R,L]"
