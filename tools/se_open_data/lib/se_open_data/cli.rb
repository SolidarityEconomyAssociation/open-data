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

    # This inserts an .htaccess file on the w3id.solidarityeconomy.coop website
    # (strictly, on the server config.DEPLOYMENT_SERVER at config.W3ID_REMOTE_LOCATION)
    def self.create_w3id
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

    private

    # escape double quotes in a string
    def self.esc(string)
      string.gsub('"', '\\"').gsub('\\', '\\\\')
    end
  end
end
