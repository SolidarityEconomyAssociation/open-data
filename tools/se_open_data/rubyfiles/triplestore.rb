#!/usr/bin/env ruby
require "./load_config"
require_relative "../lib/load_path"
require "se_open_data/utils/password_store"
require "se_open_data/utils/log_factory"
Log = SeOpenData::Utils::LogFactory.default

rsync = "rsync -avz"
ssh = "ssh"

# This gets (encrypted) passwords. Read the documentation in the class.
pass = SeOpenData::Utils::PasswordStore.new(use_env_vars: $config_map["USE_ENV_PASSWORDS"])
Log.debug "Checking ENV for passwords" if pass.use_env_vars?

begin
  if !File.file?($config_map["VIRTUOSO_SCRIPT_LOCAL"])
    Log.debug "Creating #{$config_map["VIRTUOSO_SCRIPT_LOCAL"]}"
    
    get_rdfxml_curl = 'curl --silent -H "Accept: application/rdf+xml" -L'
    get_rdfxml = -> (x,y) {system("echo 'Creating #{y} from #{x}' && #{get_rdfxml_curl} #{x} > #{y}")}
    get_rdfxml_for_virtuoso = -> (x,y) {get_rdfxml.call(x,$config_map["GEN_VIRTUOSO_DIR"]+y)}

    get_rdfxml_for_virtuoso.call($config_map["ESSGLOBAL_URI"]+"vocab/","essglobal_vocab.rdf")
    get_rdfxml_for_virtuoso.call($config_map["ESSGLOBAL_URI"]+"standard/organisational-structure","organisational-structure.skos")

    system("echo 'Creating #{$config_map["VIRTUOSO_NAMED_GRAPH_FILE"]}'")
    system("echo '#{$config_map["GRAPH_NAME"]}' > #{$config_map["VIRTUOSO_NAMED_GRAPH_FILE"]}")

    system("echo 'Creating #{$config_map["VIRTUOSO_SCRIPT_LOCAL"]}'")
    system("echo \"SPARQL CLEAR GRAPH '#{$config_map["GRAPH_NAME"]}';\" > #{$config_map["VIRTUOSO_SCRIPT_LOCAL"]} ")
    system("echo \"ld_dir('#{$config_map["VIRTUOSO_DATA_DIR"]}','*.rdf',NULL);\" >> #{$config_map["VIRTUOSO_SCRIPT_LOCAL"]}")
    system("echo \"ld_dir('#{$config_map["VIRTUOSO_DATA_DIR"]}','*.skos',NULL);\" >> #{$config_map["VIRTUOSO_SCRIPT_LOCAL"]}")
    system("echo \"rdf_loader_run();\" >> #{$config_map["VIRTUOSO_SCRIPT_LOCAL"]}")


    system("echo Transfering directory '#{$config_map["GEN_VIRTUOSO_DIR"]}' to virtuoso server '#{$config_map["DEPLOYMENT_SERVER"]}':#{$config_map["VIRTUOSO_DATA_DIR"]}")
    system("#{ssh} #{$config_map["DEPLOYMENT_SERVER"]} 'mkdir -p #{$config_map["VIRTUOSO_DATA_DIR"]}'")
    system("#{rsync} #{$config_map["GEN_VIRTUOSO_DIR"]} #{$config_map["DEPLOYMENT_SERVER"]}:#{$config_map["VIRTUOSO_DATA_DIR"]}")


    if($config_map["AUTO_LOAD_TRIPLETS"])
      puts "ssh -T #{$config_map["DEPLOYMENT_SERVER"]} 'isql-vt localhost dba ******** #{$config_map["VIRTUOSO_SCRIPT_REMOTE"]}'"
      pass = pass.get $config_map["VIRTUOSO_PASS_FILE"]
      system("ssh #{$config_map["DEPLOYMENT_SERVER"]} 'isql-vt localhost dba #{pass} #{$config_map["VIRTUOSO_SCRIPT_REMOTE"]}'")
    else
      puts <<HERE
****
**** IMPORTANT! ****
**** The final step is to load the data into Virtuoso with graph named #{$config_map["GRAPH_NAME"]}.
**** Execute the following command, providing the password for the Virtuoso dba user:
****\tssh #{$config_map["DEPLOYMENT_SERVER"]} 'isql-vt localhost dba ******** #{$config_map["VIRTUOSO_SCRIPT_REMOTE"]}
HERE
    end
  else
    puts "File exists, nothing to do: #{$config_map['VIRTUOSO_SCRIPT_LOCAL']}"
  end
rescue
  # Delete this output file, and rethrow
  File.delete $config_map['VIRTUOSO_SCRIPT_LOCAL']
  raise
end
