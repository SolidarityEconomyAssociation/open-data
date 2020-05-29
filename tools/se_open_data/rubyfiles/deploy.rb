#!/usr/bin/env ruby
require_relative "../lib/load_path"
require "se_open_data/config"

# this just does an rsync, after creating the target directory

config_file = Dir.glob('settings/{config,defaults}.txt').first 
config = SeOpenData::Config.new 'settings/config.txt', Dir.pwd

rsync = "rsync -avz --no-perms --omit-dir-times"
ssh = "ssh"

ssh_mkdir_cmd = "#{ssh} #{config.DEPLOYMENT_SERVER} "+
    "'cd #{config.DEPLOYMENT_WEBROOT} && mkdir -p #{config.DEPLOYMENT_DOC_SUBDIR}'" 

rsync_cmd = "#{rsync} #{config.DEPLOYMENT_RSYNC_FLAGS} "+
    "#{config.GEN_DOC_DIR} #{config.DEPLOYMENT_SERVER}:#{config.DEPLOYMENT_DOC_DIR}"


#fail early
cmnd = ssh_mkdir_cmd + " && " + rsync_cmd
puts cmnd
system(cmnd)
