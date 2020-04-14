require "./load_config"

rsync = "rsync -avz --no-perms --omit-dir-times"
ssh = "ssh"

ssh_mkdir_cmd = "#{ssh} #{$config_map["DEPLOYMENT_SERVER"]} "+
    "'cd #{$config_map["DEPLOYMENT_WEBROOT"]} && mkdir -p #{$config_map["DEPLOYMENT_DOC_SUBDIR"]}'" 

rsync_cmd = "#{rsync} #{$config_map["DEPLOYMENT_RSYNC_FLAGS"]} "+
    "#{$config_map["GEN_DOC_DIR"]} #{$config_map["DEPLOYMENT_SERVER"]}:#{$config_map["DEPLOYMENT_DOC_DIR"]}"


#fail early
cmnd = ssh_mkdir_cmd + " && " + rsync_cmd
puts cmnd
system(cmnd)