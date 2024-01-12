#!/bin/bash
set -vx
set -e

. defs.sh

mkdir -p $OUTDIR

# Safety first - don't blindly overwrite database if it exists
if [ -e $DB ]; then
    read -p "Overwrite $DB? [Y/N]" response
    if [[ "$response" == "Y" ]]; then
	rm -f $DB;
    else
	echo "Stopping."
	exit 1;
    fi
fi

curl -f $DC_URL >$DC_CSV
#curl -f $ICA_URL >$ICA_CSV
curl -f $NCBA_URL >$NCBA_CSV
curl -f $CUK_URL >$CUK_CSV


# --blanks is important otherwise 'NA', 'N/A', 'none' or 'null' -> null!
csvsql --db sqlite:///$DB --tables $DC_TB --blanks --insert $DC_CSV
csvsql --db sqlite:///$DB --tables $ICA_TB --blanks --no-constraints --insert $ICA_CSV
csvsql --db sqlite:///$DB --tables $NCBA_TB --blanks --no-constraints --insert $NCBA_CSV
csvsql --db sqlite:///$DB --tables $CUK_TB --blanks --no-constraints --insert $CUK_CSV

# Add Domains field to $DC_TB
sqlite3 $DB "alter table $DC_TB add column Domains VARCHAR"

# For ICA, CUK: Copy Website URLs as Domain
for TB in $ICA_TB $CUK_TB; do
    # Add Domain field
    sqlite3 $DB "alter table $TB add column Domain VARCHAR"
    sqlite3 $DB "update $TB set Domain = Website"
done

# For ICA, NCBA - make the Identifier field an integer (not a real)
# Otherwise, sqlite will insert a trailing '.0' on export
for TB in $ICA_TB $NCBA_TB $CUK_TB; do
    sqlite3 $DB "alter table $TB add column temp INTEGER"
    sqlite3 $DB "update $TB set temp = Identifier"
    sqlite3 $DB "alter table $TB drop column Identifier"
    sqlite3 $DB "alter table $TB rename column temp to Identifier"
done

# For ICA, NCBA, CUK: clean them up into bare domains
for TB in $ICA_TB $NCBA_TB $CUK_TB; do
    # Make add a unique index on Identifier
    sqlite3 $DB "alter table $TB add column temp VARCHAR NOT NULL DEFAULT '-'"
    sqlite3 $DB "update $TB set temp = Identifier"
    sqlite3 $DB "alter table $TB drop column Identifier"
    sqlite3 $DB "alter table $TB rename column temp to Identifier"
    sqlite3 $DB "create unique index ${TB}Identifier on $TB (Identifier)"
    
    sqlite3 $DB "update $TB set Domain = lower(Domain)"
    sqlite3 $DB "update $TB set Domain = replace(Domain, 'http://', '')"
    sqlite3 $DB "update $TB set Domain = replace(Domain, 'https://', '')"
    sqlite3 $DB "update $TB set Domain = replace(Domain, 'http://', '')"
    sqlite3 $DB "update $TB set Domain = substr(Domain, 0, instr(Domain||'/','/'));" # remove paths
    sqlite3 $DB "update $TB set Domain = substr(Domain, instr(Domain, '.')+1) where Domain like '%.%.coop'"; # remove subdomains - well, one level.
    sqlite3 $DB "update $TB set Domain = substr(Domain, instr(Domain, '.')+1) where Domain like '%.%.coop'"; # second
    sqlite3 $DB "update $TB set Domain = substr(Domain, instr(Domain, '.')+1) where Domain like '%.%.coop'"; # third?
    # Remove any remaining www. subdomains
    sqlite3 $DB "update $TB set Domain = substr(Domain, instr(Domain, '.')+1) where Domain like 'www.%.%'"; # third?

    # Any orgs with lat/lng 0,0 should be set to null (this is a problem with ICA data at least,
    # which may need fixing properly upstream
    sqlite3 $DB "update $TB set Latitude = null, Longitude = null where Latitude = 0 and Longitude = 0;"
done

# Likewise for DC, copy Website into Domains and clean up (although less cleaning needed)
sqlite3 $DB "update $DC_TB set Domains = lower(Website)"
sqlite3 $DB "update $DC_TB set Domains = replace(Domains, 'http://', '')"
sqlite3 $DB "update $DC_TB set Domains = replace(Domains, 'https://', '')"

# Convert adhoc to vocab fields...?

# Compile lists of DC domains and identifiers
sqlite3  -csv $DB "select Identifier, Domains from $DC_TB" | \
    perl -nE 'chomp; ($id,$d) = split /,/; @d = split /;/, $d; say "$_,$id" for @d' >$OUTDIR/$DC_TB-domains.csv
#sqlite3  -csv $DB "select Identifier,Domain from $ICA_TB" >>$ICA_TB-domains.csv
#sqlite3  -csv $DB "select Identifier,Domain from $NCBA_TB" >>$NCBA_TB-domains.csv

# Insert the DC domains back as a new 1:* table
#for tb in $DC_TB $ICA_TB $NCBA_TB; do 
(printf "domain,${DC_FK}\n";
 cat $OUTDIR/$DC_TB-domains.csv) | \
    csvsql --db sqlite:///$DB --tables domains --insert --no-constraints -
#done

# Add $ICA_FK and $NCBA_FK fields, and indexes on them
for FK in $ICA_FK $NCBA_FK $CUK_FK; do 
    sqlite3 $DB "alter table domains add column $FK VARCHAR"
    sqlite3 $DB "create unique index $FK on domains ($FK)"
done

# and the domains field ($DC_FK there already)
sqlite3 $DB "create index domain on domains (domain)"
sqlite3 $DB "create index $DC_FK on domains ($DC_FK)"

# Before we add more domains from other datasets, create a table
# linking all the .coop domains to their DC registrant orgs.
sqlite3 $DB "create table dc_domains as select domain, dcid from domains;"


# Create foreign refs from domains to $NCBA_TB and $ICA_TB
# tables based on Domains/Domain matches
sqlite3 $DB "insert into domains (domain,$ICA_FK) select $ICA_TB.Domain,$ICA_TB.Identifier from $ICA_TB;"
sqlite3 $DB "insert into domains (domain,$NCBA_FK) select $NCBA_TB.Domain,$NCBA_TB.Identifier from $NCBA_TB;"
sqlite3 $DB "insert into domains (domain,$CUK_FK) select $CUK_TB.Domain,$CUK_TB.Identifier from $CUK_TB;"

# Create a frequency table listing unique domains found and the number of times they appear in
# DC, ICA and NCBA databases
sqlite3 $DB "create table domain_freq as select domain, count(dcid) as dc, count(icaid) as ica, count(ncbaid) as ncba, count(cukid) as cuk from domains group by domain;"


# FIXME remove
# domains has all the domains, at least once
# domain_freq has all the domains just once, plus null (plus ''?)
# select all ncba,
#   left join ica on ica.domain = ncba.domain
#   left join dc on dc.id = domains.dcid and domains.domain = ncba.domain
# select all ica
#   left join ncba on ncba.domain = ica.domain
#   left join dc on dc.id = domains.dcid and domains.domain = ica.domain
#   exclude ncba
# select all
# then select all the ica with domains which have ncba freq = 0
# then select all the dc with ncba freq and ica freq = 0
#  this last step is more complicated as dc orgs can have more than one domain
#  select all the domain_freq rows where dcid is set but ica and and ncba are 0

# join dc to domain by dcid, getting one row per domain (but possible duplicate dcids)
# left join domain_freq to this by domain, to get the ica and ncba freqs
# eliminate those with non-zero


# domain ncbaid dcid icaid

#-------


# Aim: select each org from all datasets once only, and combine NCBA,
# DC and ICA information where a correspondance can be established
# based on the .coop domains.
#
# Note that only .coop domains can be guaranteed used by a single
# organisation, and even then this may be only approximately true
# (noting the re-use of APEX org domains in CUK dataset)
#
# Note: the dotcoop database is being curated to try and identify
# unique organisations but because of the way registries work, may not
# always correctly identify registrants that are the same
# organisation.
#
# Note: sometimes the DC table is inconsistent with the NCBA and ICA
# domains! So you may find .coop domains in the latter two which aren't in
# the former.
#
# Assumptions:
# - a .coop domain can only be linked to one org
# - other domains can be linked with one or more orgs
# - (assuming there are no domains inclulded not linked to an org)
# - an org can be linked to zero or more domains
#
# General procedure: somewhat like deduplicating set members in a Venn diagram,
# we take one set, then add in the others, whilst removing the overlaps. The overlaps
# get incrementally broader in each step.
#
# allorgs = dc + (ncba - dc) + (ica - dc - ncba)
#
# Partially translating into SQL logic:
# 1) dc [ join ica and ncba via dc_domains table, we know max one .coop domain each ]
# 2) + ncba without .coop [ left join to dc_domains, select null domain ] 
# 3) + ica without .coop or ncbaid [ left join to dc_domains, select null domain ]
#      [ left join ncba on domain, select null ncbid ]
# FIXME update this


# View including all ncba orgs linked to a .coop domain, along with with the dcid
sqlite3 $DB "create view ncbaid_to_dcid as \
select \
  dc_domains.dcid as dcid, \
  dc.Name as dc_name, \
  dc.Domains as dc_domains, \
  ncba.Identifier as ncbaid, \
  ncba.Name as ncba_name, \
  ncba.Domain as ncba_domain, \
  NULL as icaid, \
  NULL as ica_name, \
  NULL as ica_domain \
from ncba \
left join dc_domains, dc on \
  ncba.Domain = dc_domains.domain and \
  dc_domains.dcid = dc.Identifier
";

# Problem - two different ncba orgs link to same dc org
#dcid	dc_name	dc_domains	ncbaid	ncba_name	ncba_domain	icaid	ica_name	ica_domain
#VKoYjW	NRTC	westflorida.coop;winntelwb.coop;victoriaelectric.coop;unitedwb.coop;vecbeatthepeak.coop;trueband.coop;ruralconnect.coop;shelbywb.coop;rswb.coop;oecc.coop;pemtel.coop;nrtc.coop;noblesce.coop;northriver.coop;nepower.coop;marshallremc.coop;mytimetv.coop;llwb.coop;localexede.coop;lcwb.coop;jasperremc.coop;infinium.coop;fcremc.coop;fultoncountyremc.coop;ctv.coop;cimarron.coop;cooperativewireless.coop;ccnc.coop;buynest.coop;bvea.coop;arcadiatel.coop	8227012210.0	National Rural Telecommunications Cooperative	nrtc.coop			
#VKoYjW	NRTC	westflorida.coop;winntelwb.coop;victoriaelectric.coop;unitedwb.coop;vecbeatthepeak.coop;trueband.coop;ruralconnect.coop;shelbywb.coop;rswb.coop;oecc.coop;pemtel.coop;nrtc.coop;noblesce.coop;northriver.coop;nepower.coop;marshallremc.coop;mytimetv.coop;llwb.coop;localexede.coop;lcwb.coop;jasperremc.coop;infinium.coop;fcremc.coop;fultoncountyremc.coop;ctv.coop;cimarron.coop;cooperativewireless.coop;ccnc.coop;buynest.coop;bvea.coop;arcadiatel.coop	8227153053.0	Cooperative Council of North Carolina	ccnc.coop			

# Ditto for ICA
sqlite3 $DB "create view icaid_to_dcid as \
select \
  dc_domains.dcid as dcid, \
  dc.Name as dc_name, \
  dc.Domains as dc_domains, \
  NULL as ncbaid, \
  NULL as ncba_name, \
  NULL as ncba_domain, \
  ica.Identifier as icaid, \
  ica.Name as ica_name, \
  ica.Domain as ica_domain \
from ica \
left join dc_domains, dc on \
  ica.Domain = dc_domains.domain and \
  dc_domains.dcid = dc.Identifier \
";


# View listing all ncba non .coop orgs
sqlite3 $DB "create view ncba_not_dc_orgs as \
select \
  NULL as dcid, \
  NULL as dc_name, \
  NULL as dc_domain, \
  ncba.Identifier as ncbaid, \
  ncba.Name as ncba_name, \
  ncba.Domain as ncba_domain, \
  NULL as icaid, \
  NULL as ica_name, \
  NULL as ica_domain \
from ncba \
left join ncbaid_to_dcid as n2d on \
  ncba.Identifier = n2d.ncbaid \
where \
  n2d.ncbaid is NULL \
"

# Ditto for ICA
sqlite3 $DB "create view ica_not_dc_orgs as \
select \
  NULL as dcid, \
  NULL as dc_name, \
  NULL as dc_domain, \
  NULL as ncbaid, \
  NULL as ncba_name, \
  NULL as ncba_domain, \
  ica.Identifier as icaid, \
  ica.Name as ica_name, \
  ica.Domain as ica_domain \
from ica \
left join icaid_to_dcid as i2d on \
  ica.Identifier = i2d.icaid \
where \
  i2d.icaid is NULL \
"

# View combining the dc registered ncba and ica orgs to the matching dc orgs
sqlite3 $DB "create view dc_orgs as \
select \
  dc.Identifier as dcid, \
  dc.Name as dc_name, \
  dc.Domains as dc_domains, \
  n2d.ncbaid as ncbaid, \
  n2d.ncba_name as ncba_name, \
  n2d.ncba_domain as ncba_domain, \
  i2d.icaid as icaid, \
  i2d.ica_name as ica_name, \
  i2d.ica_domain as ica_domain \
from dc \
left join ncbaid_to_dcid as n2d on \
  dc.Identifier = n2d.dcid \
left join icaid_to_dcid as i2d on \
  dc.Identifier = i2d.dcid \
;"

# view combining dc registered, non-dc registered ncba and non-dc registered ica orgs
sqlite3 $DB "create view all_orgs as \
select * from dc_orgs
union
select * from ncba_not_dc_orgs
union
select * from ica_not_dc_orgs
;"

