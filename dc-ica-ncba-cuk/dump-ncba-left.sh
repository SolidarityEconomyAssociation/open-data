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


trace <<EOF | sqlite3 $DB -csv -header >left-ncba-dc-ica.csv
select
  Identifier, Name, 'http://'||Domain as Website,
  \`Geo Container Latitude\`, \`Geo Container Longitude\`,
  Postcode, City, \`State/Region\`, \`Country ID\`, \`Co-op Sector\`, Industry,
  \`Identifier\` is not null as \`NCBA Member\`,

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
  \`Identifier:1\` is not null as \`DC Registered\`,

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
  \`Identifier:2\` is not null as \`ICA Member\`
  
from
  ncba_x
EOF
