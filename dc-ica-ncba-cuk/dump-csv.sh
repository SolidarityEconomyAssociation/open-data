#!/bin/bash
set -e

join() {
    set +vx
    local IFS=','
    echo "$*"
}
trace() {
    set +vx
    local IN=$(cat)
    echo ">> $IN" >&2
    echo "$IN"
}

set -vx

. defs.sh

# Dump all_orgs - all NCBA/ICA/DC organsiations, linked by .coop domains where possible
# Add in extra information from original datasets.
trace <<'EOF' | sqlite3 $DB -csv -header >ncba-dc-ica.csv
select 
  'demo/plus/'||coalesce(ica.Identifier, dc.Identifier, ncba.Identifier) as Identifier,
  dc.Name,
  dc.Description,
  coalesce(ica.Website, dc.Website, ncba.Website) as Website,
  coalesce(ica.Latitude, dc.Latitude, ncba.Latitude) as Latitude,
  coalesce(ica.Longitude, dc.Longitude, ncba.Longitude) as Longitude,
  coalesce(ica.`Geo Container Latitude`, dc.`Geo Container Latitude`, ncba.`Geo Container Latitude`) as `Geo Container Latitude`,
  coalesce(ica.`Geo Container Longitude`, dc.`Geo Container Longitude`, ncba.`Geo Container Longitude`) as `Geo Container Longitude`,
  coalesce(ica.`Geo Container`, dc.`Geo Container`, ncba.`Geo Container`) as `Geo Container`,

  ncba.Identifier as `NCBA Identifier`,
  ncba.Postcode as `NCBA Postcode`,
  ncba.City as `NCBA City`,
  ncba.`State/Region` as `NCBA State/Region`,
  ncba.`Country ID` as `NCBA Country ID`,
  ncba.`Co-op Sector` as `NCBA Co-op Sector`,
  ncba.Industry as `NCBA Industry`,
  ncba.`Identifier` is not null as `NCBA Member`,

  ica.`Identifier` as `ICA Identifier`, 
  ica.`Name` as `ICA Name`,
  ica.`Street Address` as `ICA Street Address`,
  ica.`Locality` as `ICA Locality`,
  ica.`Region` as `ICA Region`,
  ica.`Postcode` as `ICA Postcode`,
  ica.`Country ID` as `ICA Country ID`,
  ica.`Website` as `ICA Website`,
  ica.`Primary Activity` as `ICA Primary Activity`,
  ica.`Activities` as `ICA Activities`,
  ica.`Organisational Structure` as `ICA Organisational Structure`,
  ica.`Membership Type` as `ICA Typology`,
  ica.`Identifier` is not null as `ICA Member`,
  
  dc.`Identifier` as `DC Identifier`, 
  dc.`Name` as `DC Name`,
  dc.`Street Address` as `DC Street Address`,
  dc.`Locality` as `DC Locality`,
  dc.`Region` as `DC Region`,
  dc.`Postcode` as `DC Postcode`,
  dc.`Country ID` as `DC Country ID`,
  dc.Domains as Domains,
  dc.`Economic Sector ID` as `DC Economic Sector`,
  dc.`Organisational Category ID` as `DC Organisational Category`,
  dc.`Identifier` is not null as `DC Registered`
from all_orgs
left join dc on all_orgs.dcid = dc.Identifier
left join ncba on all_orgs.ncbaid = ncba.Identifier
left join ica on all_orgs.icaid = ica.Identifier
EOF

echo done
