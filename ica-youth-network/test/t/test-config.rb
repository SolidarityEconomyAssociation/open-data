require_relative "../load_config.rb"
require "minitest/autorun"
require "fileutils"

Minitest::Test::make_my_diffs_pretty!

# Stubbed subclass for testing
class TestConfig < SeOpenData::Config
  def make_version # prevent this changing second to second
    "2020526214656"
  end
end

describe SeOpenData::Config do
  config_map = nil
  working_dir = File.absolute_path(__dir__ + "/working")
  
  FileUtils.mkdir_p working_dir + "/out"
  Dir.chdir working_dir + "/out" do
    config = TestConfig.new(working_dir+"/config/defaults.txt")

    config_map = config.map
  end
  
  describe "a config default instance" do

    #puts config_map
    expected_map = {
      "USE_ENV_PASSWORDS" => "false",
      "SRC_CSV_DIR" => "original-data/",
      "ORIGINAL_CSV_1" => "Youth-ledCoops.csv",
      "URI_SCHEME" => "https",
      "URI_HOST" => "w3id.solidarityeconomy.coop",
      "URI_PATH_PREFIX" => "ica-youth-network/",
      "DEPLOYMENT_SERVER" => "sea-0-admin",
      "DEPLOYMENT_WEBROOT" => "/var/www/html/data1.solidarityeconomy.coop/",
      "DEPLOYMENT_RSYNC_FLAGS" => "--delete",
      "ESSGLOBAL_URI" => "https://w3id.solidarityeconomy.coop/essglobal/V2a/",
      "VIRTUOSO_ROOT_DATA_DIR" => "/home/admin/Virtuoso/BulkLoading/Data/",
      "SPARQL_ENDPOINT" => "http://store1.solidarityeconomy.coop:8890/sparql",
      "TOP_OUTPUT_DIR" => "generated-data/",
      "STANDARD_CSV" => "generated-data/standard.csv",
      "AUTO_LOAD_TRIPLETS" => true,
      "SE_OPEN_DATA_BIN_DIR" => "/home/nick/i/gitworking/Code-Operative/SEA/open-data/ica-youth-network/tools/se_open_data/bin/",
      "SE_OPEN_DATA_LIB_DIR" => "/home/nick/i/gitworking/Code-Operative/SEA/open-data/ica-youth-network/tools/se_open_data/lib",
      "CSS_SRC_DIR" => "css/",
      "VIRTUOSO_PASS_FILE" => "deployments/dev-0.solidarityeconomy.coop/virtuoso/dba.password",
      "W3ID_REMOTE_LOCATION" => "/var/www/html/w3id.org/",
      "SERVER_ALIAS" => "data1.solidarityeconomy.coop",
      "TEST_INITIATIVE_IDENTIFIERS" => "16",
      "GEN_CSV_DIR" => "generated-data/csv/",
      "WWW_DIR" => "generated-data/www/",
      "GEN_DOC_DIR" => "generated-data/www/doc/",
      "GEN_CSS_DIR" => "generated-data/www/doc/css/",
      "GEN_VIRTUOSO_DIR" => "generated-data/virtuoso/",
      "GEN_SPARQL_DIR" => "generated-data/sparql/",
      "SPARQL_GET_ALL_FILE" => "generated-data/sparql/query.rq",
      "SPARQL_LIST_GRAPHS_FILE" => "generated-data/sparql/list-graphs.rq",
      "SPARQL_ENDPOINT_FILE" => "generated-data/sparql/endpoint.txt",
      "SPARQL_GRAPH_NAME_FILE" => "generated-data/sparql/default-graph-uri.txt",
      "DATASET_URI_BASE" => "https://w3id.solidarityeconomy.coop/ica-youth-network/",
      "GRAPH_NAME" => "https://w3id.solidarityeconomy.coop/ica-youth-network/",
      "ONE_BIG_FILE_BASENAME" => "generated-data/virtuoso/all",
      "CSS_FILES" => "",
      "SAME_AS_FILE" => "",
      "SAME_AS_HEADERS" => "",
      "DEPLOYMENT_DOC_SUBDIR" => "ica-youth-network/",
      "DEPLOYMENT_DOC_DIR" => "/var/www/html/data1.solidarityeconomy.coop/ica-youth-network/",
      "VIRTUOSO_NAMED_GRAPH_FILE" => "generated-data/virtuoso/global.graph",
      "VIRTUOSO_SQL_SCRIPT" => "loaddata.sql",
      "VERSION" => "2020526214656",
      "VIRTUOSO_DATA_DIR" => "/home/admin/Virtuoso/BulkLoading/Data/2020526214656/",
      "VIRTUOSO_SCRIPT_LOCAL" => "generated-data/virtuoso/loaddata.sql",
      "VIRTUOSO_SCRIPT_REMOTE" => "/home/admin/Virtuoso/BulkLoading/Data/2020526214656/loaddata.sql",
      "W3ID_LOCAL_DIR" => "generated-data/w3id/",
      "HTACCESS" => "generated-data/w3id/.htaccess",
      "W3ID_REMOTE_SSH" => "sea-0-admin:/var/www/html/w3id.org/ica-youth-network/",
      "REDIRECT_W3ID_TO" => "https://data1.solidarityeconomy.coop/ica-youth-network/"
    }
    
    it "should generate an expected map" do
      value(config_map).must_equal expected_map
    end
  end
end
