module SeOpenData
  # Reads a simple key-value plain-text config file.
  #
  # Values are delimited by an `=` character. Expected values are
  # expanded with some hard-wired know-how, and some directories are
  # found relative to the {base_dir} parameter, which defaults to the
  # caller script's directory.
  #
  # This is an abstraction layer from the config file itself.
  # i.e. Variables here are independant from names in the config file.
  class Config

    # @param file [String] - the path to the config file to load.
    # @param base_dir [String] - the base directory in which to locate certain paths
    def initialize(file, base_dir = Config.caller_dir)
      @config_file = file

      conf_lines = File.read(@config_file).split
      conf = {}
      conf_lines.each do |line|
        if line.split("=").length > 1
          conf[line.split("=")[0]] = line.split("=")[1]
        end
      end

      # setup Config
      # setup lib path, this needs to be changed
      conf["SE_OPEN_DATA_LIB_DIR"] = File.expand_path(conf["SE_OPEN_DATA_LIB_DIR"], base_dir)
      conf["SE_OPEN_DATA_BIN_DIR"] = File.expand_path(conf["SE_OPEN_DATA_BIN_DIR"], base_dir) + "/"

      # csv.rb
      # This is the directory where we generate intermediate csv files
      conf["GEN_CSV_DIR"] = conf["TOP_OUTPUT_DIR"] + "csv/"

      #goal end file (standard.csv)
      conf["STANDARD_CSV"] = conf["TOP_OUTPUT_DIR"] + conf["STANDARD_CSV"]
      #csv.rb end
      
      #generate.rb
      conf["WWW_DIR"] = conf["TOP_OUTPUT_DIR"] + "www/"
      conf["GEN_DOC_DIR"] = conf["WWW_DIR"] + "doc/"
      conf["GEN_CSS_DIR"] = conf["GEN_DOC_DIR"]+"css/"
      conf["GEN_VIRTUOSO_DIR"] = conf["TOP_OUTPUT_DIR"]+"virtuoso/"
      conf["GEN_SPARQL_DIR"] = conf["TOP_OUTPUT_DIR"]+"sparql/"
      conf["SPARQL_GET_ALL_FILE"] = conf["GEN_SPARQL_DIR"]+"query.rq"
      conf["SPARQL_LIST_GRAPHS_FILE"] = conf["GEN_SPARQL_DIR"]+"list-graphs.rq"
      conf["SPARQL_ENDPOINT_FILE"] = conf["GEN_SPARQL_DIR"]+"endpoint.txt"
      conf["SPARQL_GRAPH_NAME_FILE"] = conf["GEN_SPARQL_DIR"]+"default-graph-uri.txt"
      conf["DATASET_URI_BASE"] = "#{conf["URI_SCHEME"]}://#{conf["URI_HOST"]}/#{conf["URI_PATH_PREFIX"]}"
      conf["GRAPH_NAME"] = conf["DATASET_URI_BASE"]
      conf["ONE_BIG_FILE_BASENAME"] = "#{conf["GEN_VIRTUOSO_DIR"]}all"
      conf["CSS_FILES"] =  Dir[conf["CSS_SRC_DIR"]+"*.css"].join(",")
      conf["SAME_AS_FILE"] = conf.key?("SAMEAS_CSV") ? conf["SAMEAS_CSV"] : "" 
      conf["SAME_AS_HEADERS"] = conf.key?("SAMEAS_HEADERS") ? conf["SAMEAS_HEADERS"] : "" 

      #generate.rb

      #deploy.rb
      conf["DEPLOYMENT_DOC_SUBDIR"] = conf["URI_PATH_PREFIX"]
      conf["DEPLOYMENT_DOC_DIR"] = conf["DEPLOYMENT_WEBROOT"] + conf["DEPLOYMENT_DOC_SUBDIR"]

      #deploy.rb

      #triplestore.rb
      conf["VIRTUOSO_NAMED_GRAPH_FILE"]=conf["GEN_VIRTUOSO_DIR"]+"global.graph"
      conf["VIRTUOSO_SQL_SCRIPT"]="loaddata.sql"

      t = Time.now
      conf["VERSION"] = "#{t.year}#{t.month}#{t.day}#{t.hour}#{t.min}#{t.sec}"
      conf["VIRTUOSO_DATA_DIR"] = "#{conf["VIRTUOSO_ROOT_DATA_DIR"]}#{conf["VERSION"]}/"
      conf["VIRTUOSO_SCRIPT_LOCAL"] = conf["GEN_VIRTUOSO_DIR"]+conf["VIRTUOSO_SQL_SCRIPT"]
      conf["VIRTUOSO_SCRIPT_REMOTE"] = conf["VIRTUOSO_DATA_DIR"] + conf["VIRTUOSO_SQL_SCRIPT"]

      #triplestore.rb

      #create_w3id.rb
      conf["W3ID_LOCAL_DIR"] = conf["TOP_OUTPUT_DIR"] + "w3id/"
      conf["HTACCESS"] = conf["W3ID_LOCAL_DIR"] + ".htaccess"
      conf["W3ID_REMOTE_SSH"] = "#{conf["DEPLOYMENT_SERVER"]}:#{conf["W3ID_REMOTE_LOCATION"]}#{conf["URI_PATH_PREFIX"]}"
      conf["REDIRECT_W3ID_TO"] = "#{conf["URI_SCHEME"]}://#{conf["SERVER_ALIAS"]}/#{conf["URI_PATH_PREFIX"]}"
      #create_w3id.rb



      if conf.key?("AUTO_LOAD_TRIPLETS") && conf["AUTO_LOAD_TRIPLETS"].to_s.downcase == "true"
        conf["AUTO_LOAD_TRIPLETS"] = true
      else
        conf["AUTO_LOAD_TRIPLETS"] = false
      end

      #end config

      # make that dir
      system("mkdir -p " + conf["GEN_CSV_DIR"])
      system("mkdir -p " + conf["GEN_CSS_DIR"])
      system("mkdir -p " + conf["GEN_VIRTUOSO_DIR"])
      system("mkdir -p " + conf["GEN_SPARQL_DIR"])
      system("mkdir -p " + conf["W3ID_LOCAL_DIR"])

      @config_map = conf
    end
    
    # Gets the config hash
    def map
      @config_map
    end
    
    #f stands for file
    def gen_ruby_command(in_f, script, options, out_f, err_f)
      #generate ruby commands to execute ruby scripts for pipelined processes
      rb_template = "ruby -I " + @config_map["SE_OPEN_DATA_LIB_DIR"]

      command = ""

      command += "#{rb_template} #{script}"
      if options
        command += " #{options}"
      end

      if in_f
        command += " #{in_f}"
      end

      if out_f
        command += " > #{out_f}"
      end
      if out_f && err_f
        command += " > #{err_f}"
      end

      puts command
      system(command)
    end


    
    private

    # Used only in the constructor as a default value for base_dir
    def self.caller_dir
      File.dirname(caller_locations(2, 1).first.absolute_path)
    end
    
  end
end
