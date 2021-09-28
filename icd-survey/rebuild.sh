#!/bin/bash

# This script automates the whole process of rebuilding the survey
# redirection links.
#
# It needs to munge the data from a checkout of the open-data
# repository, with original and generated data in the dataset `ica`
# and `dotcoop` subdirectories, under `original-data/original.csv` and
# `generated-data/standard.csv` respectively. The dotcoop data needs
# some heuristics applied to match up `RegistrantId` in `original.csv` to
# `Identifier` in `standard.csv`.
#
# Usage:
#
#     bundle install
#     bundle exec ./rebuild.sh


# Path to the open-data repository checkout
open_data_dir=..

# Where to deploy the .htaccess and index.html files
#deploy_dest=dev-1:/var/www/vhosts/data.solidarityeconomy.coop/www/international-day-cooperatives/2021/
# This assumes the icd-survey git-repo is checked out next to open-data.
deploy_dest=$open_data_dir/../icd-survey/www/international-day-cooperatives/2021/

# Path to a temporary output directory to write datafiles
temp_output_dir=generated-data

# Where binaries are
bin=bin

set -v

mkdir -p $temp_output_dir &&

$bin/ica/generate-survey-data.rb \
    $open_data_dir/ica/generated-data/standard.csv \
    >$temp_output_dir/ica-survey-data.csv &&

$bin/dotcoop/generate-survey-data.rb \
    $open_data_dir/dotcoop/original-data/original.csv \
    $open_data_dir/dotcoop/generated-data/standard.csv \
    >$temp_output_dir/dotcoop-survey-data.csv &&

# Copy, and fix-up ICA data somewhat
$bin/apply-fixups.rb \
    $temp_output_dir/ica-survey-data.csv \
    >$temp_output_dir/combined-survey-data.csv &&

# Append DotCoop data
tail -n +2 \
     $temp_output_dir/dotcoop-survey-data.csv \
     >>$temp_output_dir/combined-survey-data.csv &&

# Make the index (this is just a convenience for testing and auditing the data)
$bin/make-index.rb $temp_output_dir/combined-survey-data.csv >$temp_output_dir/index.html &&

# Make the .htacces file containing the redirections
$bin/make-htaccess.rb $temp_output_dir/combined-survey-data.csv >$temp_output_dir/.htaccess &&

# Deploy these output files
scp -v $temp_output_dir/{index.html,.htaccess} \
    $deploy_dest

