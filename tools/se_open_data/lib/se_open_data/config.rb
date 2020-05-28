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

      @map = {}
      File.foreach(@config_file).with_index(1) do |line, num|
        next if line =~ /^\s*$/ # skip blank lines
        next if line =~ /^\s*#/ # skip comments

        # Split on the first =, trim the resulting string pair.
        # If no =, val will be nil.
        key, val = line.split("=", 2).map(&:strip)

        # Guard against invalid key characters. This is almost certainly a mistake
        raise "invalid config key '#{key}' at line #{num}" unless valid_key? key
        
        # Guard against no '='. Likewise a mistake.
        raise "config line with no '=' delimiter on line #{num}" if val.nil?
        
        # Guard against duplicates. Likewise a mistake.
        raise "config key '#{key}' duplicated on line #{num}" if @map.has_key? key

        # Add the key and value
        @map[key] = val
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

      # These keys are mandatory, because we use them below
      %w(TOP_OUTPUT_DIR SRC_CSV_DIR CSS_SRC_DIR SE_OPEN_DATA_LIB_DIR
         SE_OPEN_DATA_BIN_DIR STANDARD_CSV URI_SCHEME URI_HOST
         URI_PATH_PREFIX CSS_SRC_DIR DEPLOYMENT_WEBROOT
         VIRTUOSO_ROOT_DATA_DIR DEPLOYMENT_SERVER W3ID_REMOTE_LOCATION
         SERVER_ALIAS)
        .each do |key| 
          raise "mandatory key '#{key}' is missing" unless @map.has_key? key
        end

      
      #create_w3id.rb
      
      # Expand these paths relative to base_dir
      %w(TOP_OUTPUT_DIR SRC_CSV_DIR CSS_SRC_DIR SE_OPEN_DATA_LIB_DIR SE_OPEN_DATA_BIN_DIR)
        .each do |key| # expand rel to base_dir, append a slash
          @map[key] = join File.expand_path(@map[key], base_dir), ""
        end

      # This is the directory where we generate intermediate csv files
      @map["GEN_CSV_DIR"] = join @map["TOP_OUTPUT_DIR"], "csv", ""

      #goal end file (standard.csv)
      @map["STANDARD_CSV"] = join @map["TOP_OUTPUT_DIR"], @map["STANDARD_CSV"]
      #csv.rb end
      
      #generate.rb
      @map["WWW_DIR"] = unixjoin @map["TOP_OUTPUT_DIR"], "www", ""
      @map["GEN_DOC_DIR"] = unixjoin @map["WWW_DIR"], "doc", ""
      @map["GEN_CSS_DIR"] = unixjoin @map["GEN_DOC_DIR"], "css", ""
      @map["GEN_VIRTUOSO_DIR"] = unixjoin @map["TOP_OUTPUT_DIR"], "virtuoso", ""
      @map["GEN_SPARQL_DIR"] = unixjoin @map["TOP_OUTPUT_DIR"], "sparql", ""
      @map["SPARQL_GET_ALL_FILE"] = unixjoin @map["GEN_SPARQL_DIR"], "query.rq"
      @map["SPARQL_LIST_GRAPHS_FILE"] = unixjoin @map["GEN_SPARQL_DIR"], "list-graphs.rq"
      @map["SPARQL_ENDPOINT_FILE"] = unixjoin @map["GEN_SPARQL_DIR"], "endpoint.txt"
      @map["SPARQL_GRAPH_NAME_FILE"] = unixjoin @map["GEN_SPARQL_DIR"], "default-graph-uri.txt"
      @map["DATASET_URI_BASE"] = "#{@map["URI_SCHEME"]}://#{@map["URI_HOST"]}/#{@map["URI_PATH_PREFIX"]}"
      @map["GRAPH_NAME"] = @map["DATASET_URI_BASE"]
      @map["ONE_BIG_FILE_BASENAME"] = unixjoin @map["GEN_VIRTUOSO_DIR"], "all"
      
      @map["CSS_FILES"] =  Dir[join @map["CSS_SRC_DIR"], "*.css"].join(",")
      @map["SAME_AS_FILE"] = @map.key?("SAMEAS_CSV") ? @map["SAMEAS_CSV"] : "" 
      @map["SAME_AS_HEADERS"] = @map.key?("SAMEAS_HEADERS") ? @map["SAMEAS_HEADERS"] : "" 

      #generate.rb

      #deploy.rb
      @map["DEPLOYMENT_DOC_SUBDIR"] = @map["URI_PATH_PREFIX"]
      @map["DEPLOYMENT_DOC_DIR"] = unixjoin @map["DEPLOYMENT_WEBROOT"], @map["DEPLOYMENT_DOC_SUBDIR"]

      #deploy.rb

      #triplestore.rb
      @map["VIRTUOSO_NAMED_GRAPH_FILE"] = unixjoin @map["GEN_VIRTUOSO_DIR"], "global.graph"
      @map["VIRTUOSO_SQL_SCRIPT"] = "loaddata.sql"

      @map["VERSION"] = make_version
      @map["VIRTUOSO_DATA_DIR"] = unixjoin @map["VIRTUOSO_ROOT_DATA_DIR"], @map["VERSION"], ""
      @map["VIRTUOSO_SCRIPT_LOCAL"] = join @map["GEN_VIRTUOSO_DIR"], @map["VIRTUOSO_SQL_SCRIPT"]
      @map["VIRTUOSO_SCRIPT_REMOTE"] = unixjoin @map["VIRTUOSO_DATA_DIR"], @map["VIRTUOSO_SQL_SCRIPT"]

      #triplestore.rb

      #create_w3id.rb
      @map["W3ID_LOCAL_DIR"] = join @map["TOP_OUTPUT_DIR"], "w3id", ""
      @map["HTACCESS"] = join @map["W3ID_LOCAL_DIR"], ".htaccess"
      @map["W3ID_REMOTE_SSH"] = "#{@map["DEPLOYMENT_SERVER"]}:#{@map["W3ID_REMOTE_LOCATION"]}#{@map["URI_PATH_PREFIX"]}"
      @map["REDIRECT_W3ID_TO"] = "#{@map["URI_SCHEME"]}://#{@map["SERVER_ALIAS"]}/#{@map["URI_PATH_PREFIX"]}"
      #create_w3id.rb

      # Preserve booleans in these cases
      %w(AUTO_LOAD_TRIPLETS USE_ENV_PASSWORDS).each do |key|
        @map[key] = @map.key?(key) && @map[key].to_s.downcase == "true"
      end

      # Define an accessor method for all the keys on this instance -
      # but only if they don't exist already
      @map.each_key do |key|
        method = key.to_sym
        if !self.respond_to? method
          define_singleton_method method do
            @map[key]
          end
        end
      end

      # Make sure these dirs exist
      FileUtils.mkdir_p @map.fetch_values(
        'GEN_CSV_DIR',
        'GEN_CSS_DIR',
        'GEN_VIRTUOSO_DIR',
        'GEN_SPARQL_DIR',
        'W3ID_LOCAL_DIR'
      )
    end

    # Checks whether key is valid
    #
    # Valid keys must contain only alphanumeric characters, hyphens or underscores.
    # @return [Boolean] true if it is valid.
    def valid_key?(key)
      key !~ /\W/
    end

    # A convenient method for #map.fetch
    #
    # @param args (See Hash#fetch)
    # @return (See Hash#fetch)
    def fetch(*args)
      @map.fetch(*args)
    end

    # A convenient method for #map.has_key?
    #
    # @param args (See Hash#has_key?)
    # @return (See Hash#has_key?)
    def has_key?(key)
      @map.has_key? key
    end

    # Gets the underlying config hash
    def map
      @map
    end
    
    #f stands for file
    def gen_ruby_command(in_f, script, options, out_f, err_f)
      #generate ruby commands to execute ruby scripts for pipelined processes
      rb_template = "ruby -I " + @map["SE_OPEN_DATA_LIB_DIR"]

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
