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

# Dump the list of $NCBA_TB organisations with $DC_TB maches
NCBA_FIELDS=(
    Identifier
    Name
    Website
    Domain
    '`Street Address`'
)
DC_FIELDS=(
    Identifier
    Name
    Domains
    '`Street Address`'
)

# NCBA augmented with ICA and DC fields where matches found
trace <<EOF | sqlite3 $DB -csv -header >ncba-dc-ica.csv
select
  'demo/ncba/'||Identifier as Identifier, Name, Description, 'http://'||Domain as Website,
  Latitude, Longitude,
  \`Geo Container Latitude\`, \`Geo Container Longitude\`,

  Identifier as \`NCBA Identifier\`,
  Postcode as \`NCBA Postcode\`,
  City as \`NCBA City\`,
  \`State/Region\` as \`NCBA State/Region\`,
  \`Country ID\` as \`NCBA Country ID\`,
  \`Co-op Sector\` as \`NCBA Co-op Sector\`,
  Industry as \`NCBA Industry\`,
  \`Identifier\` is not null as \`NCBA Member\`,

  \`Identifier:2\` as \`ICA Identifier\`, 
  \`Name:2\` as \`ICA Name\`,
  \`Street Address:2\` as \`ICA Street Address\`,
  \`Locality:2\` as \`ICA Locality\`,
  \`Region:2\` as \`ICA Region\`,
  \`Postcode:2\` as \`ICA Postcode\`,
  \`Country ID:2\` as \`ICA Country ID\`,
  \`Website:2\` as \`ICA Website\`,
  \`Primary Activity:2\` as \`ICA Primary Activity\`,
  \`Activities\` as \`ICA Activities\`,
  \`Organisational Structure:2\` as \`ICA Organisational Structure\`,
  \`Membership Type:2\` as \`ICA Typology\`,
  \`Identifier:2\` is not null as \`ICA Member\`,
  
  \`Identifier:1\` as \`DC Identifier\`, 
  \`Name:1\` as \`DC Name\`,
  \`Street Address:1\` as \`DC Street Address\`,
  \`Locality:1\` as \`DC Locality\`,
  \`Region:1\` as \`DC Region\`,
  \`Postcode:1\` as \`DC Postcode\`,
  \`Country ID:1\` as \`DC Country ID\`,
  Domains,
  \`Economic Sector ID\` as \`DC Economic Sector\`,
  \`Organisational Category ID\` as \`DC Organisational Category\`,
  \`Identifier:1\` is not null as \`DC Registered\`

from
  ncba_x
EOF

# ICA not in NCBA, augmented with DC fields where matches found, and with blank NCBA fields
trace <<EOF | sqlite3 $DB -csv -header >ica-dc.csv
select
  'demo/ica/'||Identifier as Identifier, Name, Description, Website,
  Latitude, Longitude,
  \`Geo Container Latitude\`, \`Geo Container Longitude\`,

  null as \`NCBA Identifier\`,
  null as \`NCBA Postcode\`,
  null as \`NCBA City\`,
  null as \`NCBA State/Region\`,
  null as \`NCBA Country ID\`,
  null as \`NCBA Co-op Sector\`,
  null as \`NCBA Industry\`,
  0 as \`NCBA Member\`,

  \`Identifier\` as \`ICA Identifier\`, 
  \`Name\` as \`ICA Name\`,
  \`Street Address\` as \`ICA Street Address\`,
  \`Locality\` as \`ICA Locality\`,
  \`Region\` as \`ICA Region\`,
  \`Postcode\` as \`ICA Postcode\`,
  \`Country ID\` as \`ICA Country ID\`,
  \`Website\` as \`ICA Website\`,
  \`Primary Activity\` as \`ICA Primary Activity\`,
  \`Activities\` as \`ICA Activities\`,
  \`Organisational Structure\` as \`ICA Organisational Structure\`,
  \`Membership Type\` as \`ICA Typology\`,
  \`Identifier\` is not null as \`ICA Member\`,
  
  \`Identifier:1\` as \`DC Identifier\`, 
  \`Name:1\` as \`DC Name\`,
  \`Street Address:1\` as \`DC Street Address\`,
  \`Locality:1\` as \`DC Locality\`,
  \`Region:1\` as \`DC Region\`,
  \`Postcode:1\` as \`DC Postcode\`,
  \`Country ID:1\` as \`DC Country ID\`,
  Domains,
  \`Economic Sector ID\` as \`DC Economic Sector\`,
  \`Organisational Category ID\` as \`DC Organisational Category\`,
  \`Identifier:1\` is not null as \`DC Registered\`
  
from
  ica_x
EOF

# DC not in NCBA or ICA, with blank ICA and NCBA fields
trace <<EOF | sqlite3 $DB -csv -header >dc.csv
select
  'demo/dc/'||Identifier as Identifier, Name, Description, null as Website,
  Latitude, Longitude,
  \`Geo Container Latitude\`, \`Geo Container Longitude\`,

  null as \`NCBA Identifier\`,
  null as \`NCBA Postcode\`,
  null as \`NCBA City\`,
  null as \`NCBA State/Region\`,
  null as \`NCBA Country ID\`,
  null as \`NCBA Co-op Sector\`,
  null as \`NCBA Industry\`,
  0 as \`NCBA Member\`,

  null as \`ICA Identifier\`, 
  null as \`ICA Name\`,
  null as \`ICA Street Address\`,
  null as \`ICA Locality\`,
  null as \`ICA Region\`,
  null as \`ICA Postcode\`,
  null as \`ICA Country ID\`,
  null as \`ICA Website\`,
  null as \`ICA Primary Activity\`,
  null as \`ICA Activities\`,
  null as \`ICA Organisational Structure\`,
  null as \`ICA Typology\`,
  0 as \`ICA Member\`,
  
  \`Identifier\` as \`DC Identifier\`, 
  \`Name\` as \`DC Name\`,
  \`Street Address\` as \`DC Street Address\`,
  \`Locality\` as \`DC Locality\`,
  \`Region\` as \`DC Region\`,
  \`Postcode\` as \`DC Postcode\`,
  \`Country ID\` as \`DC Country ID\`,
  Domains,
  \`Economic Sector ID\` as \`DC Economic Sector\`,
  \`Organisational Category ID\` as \`DC Organisational Category\`,
  \`Identifier\` is not null as \`DC Registered\`
  
from
  dc_x
EOF
