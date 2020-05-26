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
    require 'fileutils'
    
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

      # csv.rb
      def join(*args)  # joins using local path delimiter
        File.join(*args)
      end
      def unixjoin(first, *rest) # uses the unix '/' delimiter
        #First part must have trailing slash removed only, rest must
        # have (a single) leading slash.
        first.gsub(%r{/+$},'')+rest.map {|it| it.gsub(%r{^/*},"/") }.join
      end
      
      # Expand these paths relative to base_dir
      %w(TOP_OUTPUT_DIR SRC_CSV_DIR CSS_SRC_DIR SE_OPEN_DATA_LIB_DIR SE_OPEN_DATA_BIN_DIR)
        .each do |key| # expand rel to base_dir, append a slash
          conf[key] = join File.expand_path(conf[key], base_dir), ""
        end

      # This is the directory where we generate intermediate csv files
      conf["GEN_CSV_DIR"] = join conf["TOP_OUTPUT_DIR"], "csv", ""

      #goal end file (standard.csv)
      conf["STANDARD_CSV"] = join conf["TOP_OUTPUT_DIR"], conf["STANDARD_CSV"]
      #csv.rb end
      
      #generate.rb
      conf["WWW_DIR"] = unixjoin conf["TOP_OUTPUT_DIR"], "www", ""
      conf["GEN_DOC_DIR"] = unixjoin conf["WWW_DIR"], "doc", ""
      conf["GEN_CSS_DIR"] = unixjoin conf["GEN_DOC_DIR"], "css", ""
      conf["GEN_VIRTUOSO_DIR"] = unixjoin conf["TOP_OUTPUT_DIR"], "virtuoso", ""
      conf["GEN_SPARQL_DIR"] = unixjoin conf["TOP_OUTPUT_DIR"], "sparql", ""
      conf["SPARQL_GET_ALL_FILE"] = unixjoin conf["GEN_SPARQL_DIR"], "query.rq"
      conf["SPARQL_LIST_GRAPHS_FILE"] = unixjoin conf["GEN_SPARQL_DIR"], "list-graphs.rq"
      conf["SPARQL_ENDPOINT_FILE"] = unixjoin conf["GEN_SPARQL_DIR"], "endpoint.txt"
      conf["SPARQL_GRAPH_NAME_FILE"] = unixjoin conf["GEN_SPARQL_DIR"], "default-graph-uri.txt"
      conf["DATASET_URI_BASE"] = "#{conf["URI_SCHEME"]}://#{conf["URI_HOST"]}/#{conf["URI_PATH_PREFIX"]}"
      conf["GRAPH_NAME"] = conf["DATASET_URI_BASE"]
      conf["ONE_BIG_FILE_BASENAME"] = unixjoin conf["GEN_VIRTUOSO_DIR"], "all"
      
      conf["CSS_FILES"] =  Dir[join conf["CSS_SRC_DIR"], "*.css"].join(",")
      conf["SAME_AS_FILE"] = conf.key?("SAMEAS_CSV") ? conf["SAMEAS_CSV"] : "" 
      conf["SAME_AS_HEADERS"] = conf.key?("SAMEAS_HEADERS") ? conf["SAMEAS_HEADERS"] : "" 

      #generate.rb

      #deploy.rb
      conf["DEPLOYMENT_DOC_SUBDIR"] = conf["URI_PATH_PREFIX"]
      conf["DEPLOYMENT_DOC_DIR"] = unixjoin conf["DEPLOYMENT_WEBROOT"], conf["DEPLOYMENT_DOC_SUBDIR"]

      #deploy.rb

      #triplestore.rb
      conf["VIRTUOSO_NAMED_GRAPH_FILE"] = unixjoin conf["GEN_VIRTUOSO_DIR"], "global.graph"
      conf["VIRTUOSO_SQL_SCRIPT"] = "loaddata.sql"

      conf["VERSION"] = make_version
      conf["VIRTUOSO_DATA_DIR"] = unixjoin conf["VIRTUOSO_ROOT_DATA_DIR"], conf["VERSION"], ""
      conf["VIRTUOSO_SCRIPT_LOCAL"] = join conf["GEN_VIRTUOSO_DIR"], conf["VIRTUOSO_SQL_SCRIPT"]
      conf["VIRTUOSO_SCRIPT_REMOTE"] = unixjoin conf["VIRTUOSO_DATA_DIR"], conf["VIRTUOSO_SQL_SCRIPT"]

      #triplestore.rb

      #create_w3id.rb
      conf["W3ID_LOCAL_DIR"] = join conf["TOP_OUTPUT_DIR"], "w3id", ""
      conf["HTACCESS"] = join conf["W3ID_LOCAL_DIR"], ".htaccess"
      conf["W3ID_REMOTE_SSH"] = "#{conf["DEPLOYMENT_SERVER"]}:#{conf["W3ID_REMOTE_LOCATION"]}#{conf["URI_PATH_PREFIX"]}"
      conf["REDIRECT_W3ID_TO"] = "#{conf["URI_SCHEME"]}://#{conf["SERVER_ALIAS"]}/#{conf["URI_PATH_PREFIX"]}"
      #create_w3id.rb



      if conf.key?("AUTO_LOAD_TRIPLETS") && conf["AUTO_LOAD_TRIPLETS"].to_s.downcase == "true"
        conf["AUTO_LOAD_TRIPLETS"] = true
      else
        conf["AUTO_LOAD_TRIPLETS"] = false
      end

      #end config

      # Make sure these dirs exist
      FileUtils.mkdir_p conf.fetch_values(
        'GEN_CSV_DIR',
        'GEN_CSS_DIR',
        'GEN_VIRTUOSO_DIR',
        'GEN_SPARQL_DIR',
        'W3ID_LOCAL_DIR'
      )
      
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


    protected

    # For overriding in tests
    def make_version
      t = Time.now
      "#{t.year}#{t.month}#{t.day}#{t.hour}#{t.min}#{t.sec}"
    end
    
    private

    # Used only in the constructor as a default value for base_dir
    def self.caller_dir
      File.dirname(caller_locations(2, 1).first.absolute_path)
    end
    
  end
end
