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
sqlite3 $DB -csv -header >ncba-dc-ica.csv "select * from map_data"
