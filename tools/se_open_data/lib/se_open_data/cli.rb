require "shellwords"
require "pathname"
require "se_open_data/utils/log_factory"

module SeOpenData
  class Cli
    # Create a log instance
    Log = SeOpenData::Utils::LogFactory.default
 
    def self.load_config
      require "se_open_data/config"
      config_file = Dir.glob('settings/{config,defaults}.txt').first 
      SeOpenData::Config.new 'settings/config.txt', Dir.pwd      
    end

    def self.command_run_all
      %w(convert generate deploy create_w3id triplestore).each do |name|
        puts "Running command #{name}"
        send "command_#{name}".to_sym
      end
    end

    # Removes all the generated files in the directory set by
    # {SeOpenData::Config} value `TOP_OUTPUT_DIR`
    def self.command_clean
      config = load_config
      puts "Deleting #{config.TOP_OUTPUT_DIR} and any contents."
      FileUtils.rm_rf config.TOP_OUTPUT_DIR
    end
    
    # Runs the converter.rb script in the current directory, if present
    def self.command_convert
      converter_file = File.join(Dir.pwd, 'converter')
      unless File.exist? converter_file
        raise ArgumentError, "no 'converter' file found in current directory"
      end
      unless system converter_file
        raise "converter command in current directory failed"
      end
    end
    
    def self.command_generate
      require "se_open_data/csv/standard"
      require "se_open_data/initiative/rdf"
      require "se_open_data/initiative/collection"
      config = load_config


      if !File.file?(config.ONE_BIG_FILE_BASENAME)
        # Copy contents of CSS_SRC_DIR into GEN_CSS_DIR
        FileUtils.cp_r File.join(config.CSS_SRC_DIR, '.'), config.GEN_CSS_DIR

        # Find the relative path from GEN_DOC_DIR to GEN_CSS_DIR
        doc_dir = Pathname.new(config.GEN_DOC_DIR)
        css_dir = Pathname.new(config.GEN_CSS_DIR)
        css_rel_dir = css_dir.relative_path_from doc_dir

        # Enumerate the CSS files there, relative to GEN_DOC_DIR
        css_files = Dir.glob(css_rel_dir + '**/*.css', base: config.GEN_DOC_DIR)

        #all
        IO.write config.SPARQL_ENDPOINT_FILE, config.SPARQL_ENDPOINT+"\n"
        IO.write config.SPARQL_GRAPH_NAME_FILE, config.GRAPH_NAME+"\n"

        
        rdf_config = SeOpenData::Initiative::RDF::Config.new(
          config.DATASET_URI_BASE,
          config.ESSGLOBAL_URI,
          config.ONE_BIG_FILE_BASENAME,
          config.SPARQL_GET_ALL_FILE,
          css_files,
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

    def self.command_deploy
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

    # This inserts an .htaccess file on the w3id.solidarityeconomy.coop website
    # (strictly, on the server config.DEPLOYMENT_SERVER at config.W3ID_REMOTE_LOCATION)
    def self.command_create_w3id
      config = load_config

      # Create w3id config
      redir = config.REDIRECT_W3ID_TO

      htaccess = <<-HERE
# Turn off MultiViews
Options -MultiViews +FollowSymLinks

# Directive to ensure *.rdf files served as appropriate content type,
# if not present in main apache config
AddType application/rdf+xml .rdf

# Rewrite engine setup
RewriteEngine On

# Redirect sparql queries for this dataset.
# store1 is where the Virtuoso triplestore is served.
# This is close, but does not work from curl as expected... e.g. with this:
#bombyx:~/SEA/open-data-and-maps/data/dotcoop/domains2018-04-24$ curl -i -L -H \"Accept: application/json\"  --data-urlencode query@generated-data/experimental/sparql/query.rq http://w3id.solidarityeconomy.coop/ica-youth-network/sparql
#RewriteRule ^(sparql)$ http://store1.solidarityeconomy.coop:8890/$1?default-graph-uri=https://w3id.solidarityeconomy.coop/ica-youth-network/ [QSA,R=303,L]

# Redirect https://w3id.org/dotcoop to the appropriate index,
# content negotiation depending on the HTTP Accept header:
RewriteCond %{HTTP_ACCEPT} !application/rdf\+xml.*(text/html|application/xhtml\+xml)
RewriteCond %{HTTP_ACCEPT} text/html [OR]
RewriteCond %{HTTP_ACCEPT} application/xhtml\+xml [OR]
RewriteCond %{HTTP_USER_AGENT} ^Mozilla/.*
RewriteRule ^$ #{redir}index.html [R=303,L]

RewriteCond %{HTTP_ACCEPT} application/rdf\+xml
RewriteRule ^$ #{redir}index.rdf [R=303,L]

RewriteCond %{HTTP_ACCEPT} text/turtle
RewriteRule ^$ #{redir}index.ttl [R=303,L]

# Redirect https://w3id.org/ica-youth-network/X to the appropriate file on data1.solidarityeconomy.coop
# In this case, X will refer to a specific Coop.
# Content negotiation depending on the HTTP Accept header:
RewriteCond %{HTTP_ACCEPT} !application/rdf\+xml.*(text/html|application/xhtml\+xml)
RewriteCond %{HTTP_ACCEPT} text/html [OR]
RewriteCond %{HTTP_ACCEPT} application/xhtml\+xml [OR]
RewriteCond %{HTTP_USER_AGENT} ^Mozilla/.*
RewriteRule ^(.*)$ #{redir}$1.html [R=303,L]

RewriteCond %{HTTP_ACCEPT} application/rdf\+xml
RewriteRule ^(.*)$ #{redir}$1.rdf [R=303,L]

RewriteCond %{HTTP_ACCEPT} text/turtle
RewriteRule ^(.*)$ #{redir}$1.ttl [R=303,L]

# Default rule. Apparently, some older Linked Data applications assume this default (sigh):
RewriteRule ^(.*)$ #{redir}$1.rdf [R=303,L]
HERE

      puts "creating htaccess file.."
      IO.write(config.HTACCESS, htaccess)
      
      ssh_cmd = <<-HERE
cd "#{esc config.W3ID_REMOTE_LOCATION}" &&
mkdir -p "#{config.URI_PATH_PREFIX}"
HERE
      
      ssh = <<-HERE
ssh "#{esc config.DEPLOYMENT_SERVER}" "#{ssh_cmd}"
HERE
      puts ssh
      unless system ssh
        raise "shell command failed"
      end

      # Ensure these paths have trailing slashes, for rsync these are
      # significant!
      src = File.join(config.W3ID_LOCAL_DIR, '')
      dest = File.join(config.W3ID_REMOTE_SSH, '')
      
      rsync = <<-HERE
rsync -a "#{esc src}" "#{esc dest}"
HERE
      puts rsync
      unless system rsync
        raise "shell command failed"
      end
    end

    # Uploads the linked-data graph to the Virtuoso triplestore server
    def self.command_triplestore
      require "se_open_data/utils/password_store"

      config = load_config

      # This gets (encrypted) passwords. Read the documentation in the class.
      pass = SeOpenData::Utils::PasswordStore.new(use_env_vars: config.USE_ENV_PASSWORDS)
      Log.debug "Checking ENV for passwords" if pass.use_env_vars?

      if !File.file?(config.VIRTUOSO_SCRIPT_LOCAL)
        Log.debug "Creating #{config.VIRTUOSO_SCRIPT_LOCAL}"
        
        content = fetch config.ESSGLOBAL_URI+"vocab/"
        IO.write File.join(config.GEN_VIRTUOSO_DIR, "essglobal_vocab.rdf"), content

        content = fetch config.ESSGLOBAL_URI+"standard/organisational-structure"
        IO.write File.join(config.GEN_VIRTUOSO_DIR, "organisational-structure.skos"), content
        
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
        
        unless system <<HERE
ssh #{config.DEPLOYMENT_SERVER} 'mkdir -p #{config.VIRTUOSO_DATA_DIR}' &&
rsync -avz #{config.GEN_VIRTUOSO_DIR} #{config.DEPLOYMENT_SERVER}:#{config.VIRTUOSO_DATA_DIR}
HERE
          raise "rsync failed"
        end
        
        if(config.AUTO_LOAD_TRIPLETS)
          pass = pass.get config.VIRTUOSO_PASS_FILE
          puts autoload_cmd "<PASSWORD>", config
          unless system autoload_cmd pass, config
            raise "autoload triplets failed"
          end
        else
          puts <<HERE
****
**** IMPORTANT! ****
**** The final step is to load the data into Virtuoso with graph named #{config.GRAPH_NAME}.
**** Execute the following command, providing the password for the Virtuoso dba user:
****\t#{autoload_cmd "<PASSWORD>", config}
HERE
        end
      else
        puts "File exists, nothing to do: #{config.VIRTUOSO_SCRIPT_LOCAL}"
      end
    rescue
      # Delete this output file, and rethrow
      File.delete config.VIRTUOSO_SCRIPT_LOCAL if File.exist? config.VIRTUOSO_SCRIPT_LOCAL
      raise
    end

    private

    # generates the autoload command, with the given password
    def self.autoload_cmd(pass, config)
      isql = <<-HERE
isql-vt localhost dba "#{esc pass}" "#{esc config.VIRTUOSO_SCRIPT_REMOTE}"
HERE
      return <<-HERE
ssh -T "#{esc config.DEPLOYMENT_SERVER}" "#{esc isql.chomp}"
HERE
    end

    # escape double quotes in a string
    def self.esc(string)
      string.gsub('"', '\\"').gsub('\\', '\\\\')
    end

    # Gets the content of an URL, following redirects
    #
    # Also sets the 'Accept: application/rdf+xml' header.
    #
    # @return the query content
    def self.fetch(uri_str, limit = 10)
      require 'net/http'
      raise ArgumentError, 'too many HTTP redirects' if limit == 0

      uri = URI(uri_str)
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/rdf+xml'

      puts "fetching #{uri}"
      response = Net::HTTP.start(
        uri.hostname, uri.port,
        :use_ssl => uri.scheme == 'https') do |http|
        
        http.request(request)
      end

      case response
      when Net::HTTPSuccess then
        response.body
      when Net::HTTPRedirection then
        location = response['location']
        warn "redirected to #{location}"
        fetch(location, limit - 1)
      else
        response.value
      end
    end

  end
end
