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
csvsql --db sqlite:///$DB --tables $ICA_TB --blanks --insert $ICA_CSV
csvsql --db sqlite:///$DB --tables $NCBA_TB --blanks --insert $NCBA_CSV
csvsql --db sqlite:///$DB --tables $CUK_TB --blanks --insert $CUK_CSV

# Add Domains field to $DC_TB
sqlite3 $DB "alter table $DC_TB add column Domains TEXT"

# For ICA, CUK: Copy Website URLs as Domain
for TB in $ICA_TB $CUK_TB; do
    # Add Domain field
    sqlite3 $DB "alter table $TB add column Domain TEXT"
    sqlite3 $DB "update $TB set Domain = Website"
done

# For ICA, NCBA, CUK: clean them up into bare domains
for TB in $ICA_TB $NCBA_TB $CUK_TB; do 
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
    sqlite3 $DB "alter table domains add column $FK TEXT"
    sqlite3 $DB "create unique index $FK on domains ($FK)"
done

# and the domains field ($DC_FK there already)
sqlite3 $DB "create index domain on domains (domain)"
sqlite3 $DB "create index $DC_FK on domains ($DC_FK)"

# Create foreign refs from domains to $NCBA_TB and $ICA_TB
# tables based on Domains/Domain matches
sqlite3 $DB "insert into domains (domain,$ICA_FK) select $ICA_TB.Domain,$ICA_TB.Identifier from $ICA_TB;"
sqlite3 $DB "insert into domains (domain,$NCBA_FK) select $NCBA_TB.Domain,$NCBA_TB.Identifier from $NCBA_TB;"
sqlite3 $DB "insert into domains (domain,$CUK_FK) select $CUK_TB.Domain,$CUK_TB.Identifier from $CUK_TB;"

# Create a frequency table listing unique domains found and the number of times they appear in
# DC, ICA and NCBA databases
sqlite3 $DB "create table domain_freq as select domain, count(dcid) as dc, count(icaid) as ica, count(ncbaid) as ncba, count(cukid) as cuk from domains group by domain;"

# View left joining ICA and DC to NCBA. i.e. All the NCB orgs.
# Duplicate fields are disambiguated with a :X suffix, using incrementing indexes as X.
sqlite3 $DB "create view ncba_x as select ncba.*, dc.*,ica.* from ncba left join (select * from domains, dc where domains.dcid = dc.Identifier) as dc on dc.domain = ncba.domain left join ica on ica.Domain = ncba.Domain and ica.Domain like '%.coop'";

# View left joining DC to ICA. i.e. All the ICA orgs not in ncba_x FIXME or DC?
sqlite3 $DB "create view ica_x as select ica.*, dc_domains.* from ica left join dc_domains on dc_domains.domain = ica.Domain;"

# All the DC domains not in NCBA FIXME or ICA?
sqlite3 $DB "create view dc_x as select count(dc.Identifier) as NumDomains,dc.* from dc left join (select distinct domains.domain, domains.dcid from domains, domain_freq where domains.domain = domain_freq.domain and domain_freq.ncba = 0 and domain_freq.ica = 0 and domain_freq.cuk = 0) as d on d.dcid = dc.Identifier  group by dc.Identifier;"

# All the domains linked to DC orgs
sqlite3 $DB "create view dc_domains as select * from domains, dc where domains.dcid = dc.Identifier;"

