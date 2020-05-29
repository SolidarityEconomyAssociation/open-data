#!/usr/bin/env ruby
require_relative "../lib/load_path"
require "se_open_data/config"

config_file = Dir.glob('settings/{config,defaults}.txt').first 
config = SeOpenData::Config.new 'settings/config.txt', Dir.pwd

if !File.file?(config.ONE_BIG_FILE_BASENAME)
  # Copy contents of CSS_SRC_DIR into GEN_CSS_DIR
  FileUtils.cp_r File.join(config.CSS_SRC_DIR, '.'), config.GEN_CSS_DIR


  #all
  system("echo '#{config.SPARQL_ENDPOINT}' > #{config.SPARQL_ENDPOINT_FILE}")
  system("echo '#{config.GRAPH_NAME}' > #{config.SPARQL_GRAPH_NAME_FILE}")

  csv_to_rdf = config.SE_OPEN_DATA_BIN_DIR+"csv/standard/csv-to-rdf.rb"

  options = ["--output-directory #{config.GEN_DOC_DIR} ",
  "--uri-prefix #{config.DATASET_URI_BASE} ",
  "--essglobal-uri #{config.ESSGLOBAL_URI} ",
  "--one-big-file-basename #{config.ONE_BIG_FILE_BASENAME} ",
  "--sameas-csv '#{config.SAME_AS_FILE}' ",
  "--sameas-headers '#{config.SAME_AS_HEADERS}' ",
  "--map-app-sparql-query-filename #{config.SPARQL_GET_ALL_FILE} ",
  "--css-files '#{config.CSS_FILES}'"].join("\\\n")

  in_file = config.STANDARD_CSV

  config.gen_ruby_command(in_file,csv_to_rdf,options,nil,nil)
else
  puts "Work done already"
end
