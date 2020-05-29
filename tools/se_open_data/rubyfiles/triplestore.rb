#!/usr/bin/env ruby
require_relative "../lib/load_path"
require "se_open_data/config"
require "se_open_data/utils/password_store"
require "se_open_data/utils/log_factory"

config_file = Dir.glob('settings/{config,defaults}.txt').first 
config = SeOpenData::Config.new 'settings/config.txt', Dir.pwd

Log = SeOpenData::Utils::LogFactory.default

rsync = "rsync -avz"
ssh = "ssh"

# This gets (encrypted) passwords. Read the documentation in the class.
pass = SeOpenData::Utils::PasswordStore.new(use_env_vars: config.USE_ENV_PASSWORDS)
Log.debug "Checking ENV for passwords" if pass.use_env_vars?

def get_rdfxml(x,y)
  puts "Creating #{y} from #{x}"
  system "curl --silent -H 'Accept: application/rdf+xml' -L '#{x}' > '#{y}'"
end

begin
  if !File.file?(config.VIRTUOSO_SCRIPT_LOCAL)
    Log.debug "Creating #{config.VIRTUOSO_SCRIPT_LOCAL}"
   
    get_rdfxml(
      config.ESSGLOBAL_URI+"vocab/",
      File.join(config.GEN_VIRTUOSO_DIR, "essglobal_vocab.rdf")
    )
    get_rdfxml(
      config.ESSGLOBAL_URI+"standard/organisational-structure",
      File.join(config.GEN_VIRTUOSO_DIR, "organisational-structure.skos")
    )
    
    puts "Creating #{config.VIRTUOSO_NAMED_GRAPH_FILE}"
    IO.write config.VIRTUOSO_NAMED_GRAPH_FILE, config.GRAPH_NAME

    puts "Creating #{config.VIRTUOSO_SCRIPT_LOCAL}"
    IO.write config.VIRTUOSO_SCRIPT_LOCAL, <<HERE
SPARQL CLEAR GRAPH '#{config.GRAPH_NAME}';
ld_dir('#{config.VIRTUOSO_DATA_DIR}','*.rdf',NULL);
ld_dir('#{config.VIRTUOSO_DATA_DIR}','*.skos',NULL);
rdf_loader_run();
HERE
    
    puts "Transfering directory '#{config.GEN_VIRTUOSO_DIR}' to virtuoso server '#{config.DEPLOYMENT_SERVER}':#{config.VIRTUOSO_DATA_DIR}"
                                                  
    system <<HERE
#{ssh} #{config.DEPLOYMENT_SERVER} 'mkdir -p #{config.VIRTUOSO_DATA_DIR}' &&
#{rsync} #{config.GEN_VIRTUOSO_DIR} #{config.DEPLOYMENT_SERVER}:#{config.VIRTUOSO_DATA_DIR}
HERE

    if(config.AUTO_LOAD_TRIPLETS)
      puts "#{ssh} -T #{config.DEPLOYMENT_SERVER} 'isql-vt localhost dba ******** #{config.VIRTUOSO_SCRIPT_REMOTE}'"
      pass = pass.get config.VIRTUOSO_PASS_FILE
      system("#{ssh} #{config.DEPLOYMENT_SERVER} 'isql-vt localhost dba #{pass} #{config.VIRTUOSO_SCRIPT_REMOTE}'")
    else
      puts <<HERE
****
**** IMPORTANT! ****
**** The final step is to load the data into Virtuoso with graph named #{config.GRAPH_NAME}.
**** Execute the following command, providing the password for the Virtuoso dba user:
****\tssh #{config.DEPLOYMENT_SERVER} 'isql-vt localhost dba ******** #{config.VIRTUOSO_SCRIPT_REMOTE}
HERE
    end
  else
    puts "File exists, nothing to do: #{config.VIRTUOSO_SCRIPT_LOCAL}"
  end
rescue
  # Delete this output file, and rethrow
  File.delete config.VIRTUOSO_SCRIPT_LOCAL
  raise
end
