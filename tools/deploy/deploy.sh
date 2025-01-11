#!/bin/bash

# NAME
#
#    deploy.sh
#
# SYNOPSIS
#
# This script performs an initial installation of the open-data service.
#
# USAGE
#
# Ensure prerequisites are satisfied first. (See below.)
#
# Next, set the requisite SEOD_ and PASSWORD__ environment variables
# (see definitions in the script source), and run `deploy.sh`.
#
# The script is stored in the repo but can be run outside of it.
#
# Note, how you get it out depends on the context, see
# https://stackoverflow.com/questions/1125476
#
# TL;DR: for GitHub, use the curl command below (substituing your
# branch of choice for `master` if necessary):
#
#    curl https://raw.github.com/DigitalCommons/open-data/master/tools/deploy/deploy.sh | bash
#
# For example, here is a typical-ish deploy case I am considering at
# the time of writing:
#
# - use code from a specific branch `my-feature`
# - deploy code in the `gitworking` directory
# - for the current user
# - force static data output to go in ~/public_html
#   (i.e. no remote deployment, whatever is configured)
# - likewise, force bulk-uploading direct to a local Virtuoso server
# - define the passwords needed for the datasets in this branch
#   (obtained from a local password store using `pass`)
#
# Also note that usually you would automate this in your deploy
# process. I am not expecting this to be something you type manually
# each time. This isn't already automated by the script in order to
# avoid hard dependencies on `pass` nor on specific configurations.
#
#     export SEOD_HOME_DIR=$HOME
#     export SEOD_USERNAME=$USER
#     export SEOD_WORKING_DIR=gitworking
#     export SEOD_GIT_BRANCH=my-feature
#     export SEOD_DEPLOY_PARAMS="--owner . --group . $HOME/public_html"
#     export SEOD_TRIPLESTORE_PARAMS="--no-via"
#     ids=( \
#       geoapifyAPI.txt \
#       services/mapbox/landexplorer.txt \
#       people/nick/lime-survey.password \
#       accounts/airtable.com/data-factory-download.apikey \
#       deployments/dev-2.digitalcommons.coop/virtuoso/dba.password \
#     )
#     for id in "${ids[@]}"; do
#        name=${id//[^a-zA-Z0-9]/_}
#        export PASSWORD__${name^^}="$(pass $id)"
#     done
# 
#     wget https://raw.github.com/DigitalCommons/open-data/$SEOD_GIT_BRANCH/tools/deploy/deploy.sh
#     bash deploy.sh
#
# This will:
# - check out the repository
# - create an .env file to persist your configuration
# - run the `post-pull.rb` script to set up a systemd service and timer
#   that runs the datafactory process periodically (and supporting scripts)
#
# The service should then run at the period specified (defaults to
# every 10 minutes), deploy its outputs, and mail notifications of any errors.
#
# MANAGEMENT
#
# Status can be checked with:
#
#    systemctl status --user se_open_data
#
#    journalctl --user -u se_open_data
#
# (You may need to amend these if you set a different service unit
# name, or are not running in user mode)
#
# PREREQUISITES
#
# - Assumes Linux (probably Debian or a derivative), with systemd.
# - ASDF installed and configured (so that Ruby and Bundler can be installed).
# - Network access to the source data.
# - A local (or possibly remote) location to deploy static output files to
# - A local (or possibly remote) Virtuoso triplestore to deploy linked data to.
# - Bash and the usual Linux CLI toolchain
# - Git
# - The `mail` utility (needs `mailutils` package on Debian, and a means to deliver mail configured)
# - Typically, designed to runs as a regular user. Running as root is not necessary, but
#   may still work.
# - If run as a user, systemd's linger mode needs to be enabled for
#   that user (`loginctl enable-linger $USER`), and the
#   DBUS_SESSION_BUS_ADDRESS variable needs to be set
#   (`export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$UID/bus`)

set -o errexit
set -o pipefail
set -vx

# We expect/allow certain environment variables as configuration, as
# follows. Those defined as :? must be present; those with := have
# defaults set. These, and other variables you can set, are documented
# in more detail in post-pull.rb.
: ${SEOD_HOME_DIR:?}
: ${SEOD_WORKING_DIR:?}
: ${SEOD_GIT_REPO:=https://github.com/DigitalCommons/open-data/}
: ${SEOD_GIT_BRANCH:=master}
: ${SEOD_ENV_FILE:=.env}

# Add the ruby and bundler plugins from asdf
asdf plugin add ruby
asdf plugin add bundler

DEPLOY_DIR=$SEOD_HOME_DIR/$SEOD_WORKING_DIR # scripts assume this working dir
rm -rf "$DEPLOY_DIR"

# write the .env file
ENV_FILE=${SEOD_HOME_DIR}/${SEOD_ENV_FILE}
echo >"$ENV_FILE" # create empty
chmod go-rw "$ENV_FILE" # make it unreadable first
env | sort | egrep '^(SEOD|PASSWORD_)_' >"$ENV_FILE" # dump relevant

mkdir -p $DEPLOY_DIR
# GitHub doesn't support git-archive so we use the init-and-remote-add method
(
  cd $DEPLOY_DIR
  git init
  git remote add origin $SEOD_GIT_REPO
  git fetch --depth=1 origin $SEOD_GIT_BRANCH
  git checkout $SEOD_GIT_BRANCH
  git reset --hard origin/$SEOD_GIT_BRANCH
  ./tools/deploy/post-pull.rb
)
