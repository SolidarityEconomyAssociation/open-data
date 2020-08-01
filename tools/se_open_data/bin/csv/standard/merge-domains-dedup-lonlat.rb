# Merges domains in rows of CSV that contain identical IDs.
# A duplicate is defined as having the same keys as a previous row.
# OR if all other fields except the key field and the domain field are equal

# $LOAD_PATH.unshift '/Volumes/Extra/SEA-dev/open-data-and-maps/data/tools/se_open_data/lib'
require "se_open_data"


domainHeader = SeOpenData::CSV::Standard::V1::Headers[:homepage]
nameHeader = SeOpenData::CSV::Standard::V1::Headers[:name]
lat = SeOpenData::CSV::Standard::V1::Headers[:geocontainer_lat]
lon = SeOpenData::CSV::Standard::V1::Headers[:geocontainer_lon]


SeOpenData::CSV.merge_and_remove_latlon_dups(
  ARGF.read,
  $stdout,
  domainHeader,
  nameHeader,
  lat,
  lon
)
