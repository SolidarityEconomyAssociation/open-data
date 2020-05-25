#!/usr/bin/env ruby
require "./load_config"


rsync = "rsync -avz"
ssh = "ssh"


if !File.file?($config_map["VIRTUOSO_SCRIPT_LOCAL"])

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
        puts "ssh #{$config_map["DEPLOYMENT_SERVER"]} 'isql-vt localhost dba #{$config_map["VIRTUOSO_PASS"]} #{$config_map["VIRTUOSO_SCRIPT_REMOTE"]}'"
        system("ssh #{$config_map["DEPLOYMENT_SERVER"]} 'isql-vt localhost dba #{$config_map["VIRTUOSO_PASS"]} #{$config_map["VIRTUOSO_SCRIPT_REMOTE"]}'")
    else
        system("echo \"****\"")
        system("echo \"**** IMPORTANT! ****\"")
        system("echo \"**** The final step is to load the data into Virtuoso with graph named #{$config_map["GRAPH_NAME"]}:\"")
        system("echo \"**** Execute the following command, providing the password for the Virtuoso dba user:\"")
        system("echo \"****\tssh #{$config_map["DEPLOYMENT_SERVER"]} 'isql-vt localhost dba #{$config_map["VIRTUOSO_PASS"]} #{$config_map["VIRTUOSO_SCRIPT_REMOTE"]}'\"")
    end    
else
    puts "File exists: #{$config_map['VIRTUOSO_SCRIPT_LOCAL']}"
end
