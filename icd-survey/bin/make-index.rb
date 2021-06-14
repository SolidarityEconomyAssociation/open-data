#!/bin/env ruby

# This generates an index.html file showing the data used to create
# prefilled survey URL links.  A link to the short version is
# provided.

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
  'Name' => 'name',
  'Description' => 'description',
  'Location' => 'geoloc',
  'Website' => 'url',
  'RegistrantId' => 'dotcoopid',
  'ICAID' => 'icanum',
}

#from_path_stem = "/international-day-cooperatives/2021/#{org_id}"
from_path_stem = "."

# Print the config to stdout for a .htacccess file
# From https://serverfault.com/a/414245/421755
puts <<HERE
<http><head><meta charset="UTF-8"></head><body>
<ul>
HERE

CSV.foreach(input_csv_file, headers: true) do |row|
  if row['ICAID'].nil?
    id = row['RegistrantId']
    from_path = "#{from_path_stem}/dotcoop/#{id}"
    puts <<HERE
<li id="#{id}"><span>#{row['Name']}</span>: ID <a target="_blank" href="#{from_path}">#{row['RegistrantId']}</a></li>
HERE
  else
    id = row['ICAID']
    from_path = "#{from_path_stem}/ica/#{id}"
    puts <<HERE
<li id="#{id}"><span>#{row['Name']}</span>: ID <a target="_blank" href="#{from_path}">#{id}</a>
HERE
  end
  puts <<HERE
<ul>
<li><i>Description:</i> <pre style="white-space: break-spaces;">#{row['Description']}</pre></li>
<li><i>Domains:</i> <span>#{row['Domains']&.split(';')&.map{|d| %Q{<a id="#{d}" target="_blank" href="http://#{d}">#{d}</a>}}&.join("; ")}</span></li>
<li><i>Address:</i> <pre style="white-space: break-spaces;">#{row['Address']}</pre></li>
<li><i>Location:</i> <a target="_blank" href="https://www.openstreetmap.org/?mlat=#{row['Location'].sub(" ", "&mlon=")}">#{row['Location']}</a></li>
<li><i>Website:</i> <a href="#{row['Website']}">#{row['Website']}</a></li>
</ul></li>
HERE
end

# Default redirect for no ID
puts <<HERE 
</ul>
</body></http>
HERE
