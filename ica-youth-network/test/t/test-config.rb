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
  caller_dir = File.absolute_path(__dir__)
  generated_dir = caller_dir+"/generated-data"
  

  describe "a valid config instance" do
    config_map = nil
    
    lib_dir = File.absolute_path(__dir__+ "/../../tools/se_open_data")

    # TestConfig should recreate this + some contents
    FileUtils.rm_r generated_dir if File.exists? generated_dir

    # expansions relative to caller_dir, i.e. this script's dir
    config = TestConfig.new(caller_dir+"/config/valid.txt")

    # Make recursive directory listing here, before other tests delete it
    listing = Dir.glob(generated_dir+"/**/*", File::FNM_DOTMATCH)
                .map {|it| it.delete_prefix(generated_dir)+"\n" }
                .sort
                .join
    
    config_map = config.map
    
    #puts config_map
    expected_map = {
      "MULTI_EQUAL" => "foo=bar=baz",
      "EMPTY_EQUAL" => "",
      "with-Hyphen-Lowercase0123456789" => "# this is not a comment #",
      "WITH_PADDING" => "with padding",
      "USE_ENV_PASSWORDS" => false,
      "SRC_CSV_DIR" => caller_dir+"/original-data/",
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
      "TOP_OUTPUT_DIR" => caller_dir+"/generated-data/",
      "STANDARD_CSV" => caller_dir+"/generated-data/standard.csv",
      "AUTO_LOAD_TRIPLETS" => true,
      "SE_OPEN_DATA_BIN_DIR" => lib_dir+"/bin/",
      "SE_OPEN_DATA_LIB_DIR" => lib_dir+"/lib/",
      "CSS_SRC_DIR" => caller_dir+"/css/",
      "VIRTUOSO_PASS_FILE" => "deployments/dev-0.solidarityeconomy.coop/virtuoso/dba.password",
      "W3ID_REMOTE_LOCATION" => "/var/www/html/w3id.org/",
      "SERVER_ALIAS" => "data1.solidarityeconomy.coop",
      "TEST_INITIATIVE_IDENTIFIERS" => "16 40",
      "GEN_CSV_DIR" => caller_dir+"/generated-data/csv/",
      "WWW_DIR" => caller_dir+"/generated-data/www/",
      "GEN_DOC_DIR" => caller_dir+"/generated-data/www/doc/",
      "GEN_CSS_DIR" => caller_dir+"/generated-data/www/doc/css/",
      "GEN_VIRTUOSO_DIR" => caller_dir+"/generated-data/virtuoso/",
      "GEN_SPARQL_DIR" => caller_dir+"/generated-data/sparql/",
      "SPARQL_GET_ALL_FILE" => caller_dir+"/generated-data/sparql/query.rq",
      "SPARQL_LIST_GRAPHS_FILE" => caller_dir+"/generated-data/sparql/list-graphs.rq",
      "SPARQL_ENDPOINT_FILE" => caller_dir+"/generated-data/sparql/endpoint.txt",
      "SPARQL_GRAPH_NAME_FILE" => caller_dir+"/generated-data/sparql/default-graph-uri.txt",
      "DATASET_URI_BASE" => "https://w3id.solidarityeconomy.coop/ica-youth-network/",
      "GRAPH_NAME" => "https://w3id.solidarityeconomy.coop/ica-youth-network/",
      "ONE_BIG_FILE_BASENAME" => caller_dir+"/generated-data/virtuoso/all",
      "CSS_FILES" => caller_dir+"/css/2.css,"+caller_dir+"/css/1.css",
      "SAME_AS_FILE" => "",
      "SAME_AS_HEADERS" => "",
      "DEPLOYMENT_DOC_SUBDIR" => "ica-youth-network/",
      "DEPLOYMENT_DOC_DIR" => "/var/www/html/data1.solidarityeconomy.coop/ica-youth-network/",
      "VIRTUOSO_NAMED_GRAPH_FILE" => caller_dir+"/generated-data/virtuoso/global.graph",
      "VIRTUOSO_SQL_SCRIPT" => "loaddata.sql",
      "VERSION" => "2020526214656",
      "VIRTUOSO_DATA_DIR" => "/home/admin/Virtuoso/BulkLoading/Data/2020526214656/",
      "VIRTUOSO_SCRIPT_LOCAL" => caller_dir+"/generated-data/virtuoso/loaddata.sql",
      "VIRTUOSO_SCRIPT_REMOTE" => "/home/admin/Virtuoso/BulkLoading/Data/2020526214656/loaddata.sql",
      "W3ID_LOCAL_DIR" => caller_dir+"/generated-data/w3id/",
      "HTACCESS" => caller_dir+"/generated-data/w3id/.htaccess",
      "W3ID_REMOTE_SSH" => "sea-0-admin:/var/www/html/w3id.org/ica-youth-network/",
      "REDIRECT_W3ID_TO" => "https://data1.solidarityeconomy.coop/ica-youth-network/"
    }
    
    it "should generate an expected map" do
      value(config_map).must_equal expected_map
    end

    expected_listing = <<-HERE
/.
/csv
/csv/.
/sparql
/sparql/.
/virtuoso
/virtuoso/.
/w3id
/w3id/.
/www
/www/.
/www/doc
/www/doc/.
/www/doc/css
/www/doc/css/.
HERE
    
    it "should create the expected directories" do
      value(listing).must_equal expected_listing
    end
  end

  describe "a config instance with duplicates" do

    # TestConfig should recreate this + some contents
    FileUtils.rm_r generated_dir if File.exists? generated_dir

    it "should raise an exception" do
      err = proc do
        TestConfig.new(caller_dir+"/config/invalid-dupes.txt")
      end
              .must_raise RuntimeError
      
      err.message.must_match /config key 'SOMETHING' duplicated on line 3/
    end
  end

  describe "a config instance with a invalid keys" do

    # TestConfig should recreate this + some contents
    FileUtils.rm_r generated_dir if File.exists? generated_dir

    it "(space) should raise an exception" do
      err = proc do
        TestConfig.new(caller_dir+"/config/invalid-keys-1.txt")
      end
              .must_raise RuntimeError
      
      err.message.must_match /invalid config key 'SOMETHING ELSE' at line 2/
    end
    
    it "(colon) should raise an exception" do
      err = proc do
        TestConfig.new(caller_dir+"/config/invalid-keys-2.txt")
      end
              .must_raise RuntimeError
      
      err.message.must_match /invalid config key 'SOMETHING:ELSE' at line 2/
    end
  end
  
  describe "a config instance with missing delimiters" do

    # TestConfig should recreate this + some contents
    FileUtils.rm_r generated_dir if File.exists? generated_dir

    it "should raise an exception" do
      err = proc do
        TestConfig.new(caller_dir+"/config/invalid-delims.txt")
      end
              .must_raise RuntimeError
      
      err.message.must_match /config line with no '=' delimiter on line 2/
    end
  end
  
end