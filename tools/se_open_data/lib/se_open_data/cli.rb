require "shellwords"

module SeOpenData
  class Cli
    def self.load_config
      require "se_open_data/config"
      config_file = Dir.glob('settings/{config,defaults}.txt').first 
      SeOpenData::Config.new 'settings/config.txt', Dir.pwd      
    end
    
    def self.generate
      require "se_open_data/csv/standard"
      require "se_open_data/initiative/rdf"
      require "se_open_data/initiative/collection"
      config = load_config


      if !File.file?(config.ONE_BIG_FILE_BASENAME)
        # Copy contents of CSS_SRC_DIR into GEN_CSS_DIR
        FileUtils.cp_r File.join(config.CSS_SRC_DIR, '.'), config.GEN_CSS_DIR


        #all
        IO.write config.SPARQL_ENDPOINT_FILE, config.SPARQL_ENDPOINT+"\n"
        IO.write config.SPARQL_GRAPH_NAME_FILE, config.GRAPH_NAME+"\n"

        
        rdf_config = SeOpenData::Initiative::RDF::Config.new(
          config.DATASET_URI_BASE,
          config.ESSGLOBAL_URI,
          config.ONE_BIG_FILE_BASENAME,
          config.SPARQL_GET_ALL_FILE,
          config.CSS_FILES.split(/\s*,\s*/),
          nil, #    postcodeunit_cache?
          SeOpenData::CSV::Standard::V1,
          config.SAME_AS_FILE == ''? nil : config.SAME_AS_FILE,
          config.SAME_AS_HEADERS == ''? nil : config.SAME_AS_HEADERS
        )
        
        # Load CSV into data structures, for this particular standard
        File.open(config.STANDARD_CSV) do |input|
          input.set_encoding(Encoding::UTF_8)
          
          collection = SeOpenData::Initiative::Collection.new(rdf_config)
          collection.add_from_csv(input.read)
          collection.serialize_everything(config.GEN_DOC_DIR)
        end
      else
        puts "Work done already"
      end

    end

    def self.deploy
      config = load_config
      
      # create the remote target directory and rsync the data to it
      ssh_cmd = <<-HERE
cd "#{esc config.DEPLOYMENT_WEBROOT}" &&
mkdir -p "#{esc config.DEPLOYMENT_DOC_SUBDIR}"
HERE

      flags = "-avz --no-perms --omit-dir-times #{config.DEPLOYMENT_RSYNC_FLAGS}"
      
      # Make sure there's a trailing slash on these, for rsync,
      # they're significant!
      src = File.join(config.GEN_DOC_DIR, '')
      dest = config.DEPLOYMENT_SERVER+':'+File.join(config.DEPLOYMENT_DOC_DIR, '')
      
      cmd = <<-HERE
ssh "#{esc config.DEPLOYMENT_SERVER}" "#{esc ssh_cmd}" &&
rsync #{flags} "#{esc src}" "#{esc dest}"
HERE
      puts cmd
      unless system cmd
        raise "shell command failed"
      end
    end

    private

    # escape double quotes in a string
    def self.esc(string)
      string.gsub('"', '\\"').gsub('\\', '\\\\')
    end
  end
end
