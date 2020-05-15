#!/usr/bin/env ruby
require "./load_config"

if !File.file?($config_map["ONE_BIG_FILE_BASENAME"])
  system("rsync -r #{$config_map["CSS_SRC_DIR"]} #{$config_map["GEN_CSS_DIR"]}")


  #all
  system("echo '#{$config_map["SPARQL_ENDPOINT"]}' > #{$config_map["SPARQL_ENDPOINT_FILE"]}")
  system("echo '#{$config_map["GRAPH_NAME"]}' > #{$config_map["SPARQL_GRAPH_NAME_FILE"]}")

  csv_to_rdf = $config_map["SE_OPEN_DATA_BIN_DIR"]+"csv/standard/csv-to-rdf.rb"

  options = ["--output-directory #{$config_map["GEN_DOC_DIR"]} ",
  "--uri-prefix #{$config_map["DATASET_URI_BASE"]} ",
  "--essglobal-uri #{$config_map["ESSGLOBAL_URI"]} ",
  "--one-big-file-basename #{$config_map["ONE_BIG_FILE_BASENAME"]} ",
  "--sameas-csv '#{$config_map["SAME_AS_FILE"]}' ",
  "--sameas-headers '#{$config_map["SAME_AS_HEADERS"]}' ",
  "--map-app-sparql-query-filename #{$config_map["SPARQL_GET_ALL_FILE"]} ",
  "--css-files '#{$config_map["CSS_FILES"]}'"].join("\\\n")

  in_file = $config_map["STANDARD_CSV"]

  Config.gen_ruby_command(in_file,csv_to_rdf,options,nil,nil)
else
  puts "Work done already"
end
