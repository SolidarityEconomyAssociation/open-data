require "./load_config"




#create w3id config
redir = $config_map["REDIRECT_W3ID_TO"]

htaccess = "# Turn off MultiViews
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
RewriteRule ^(.*)$ #{redir}$1.rdf [R=303,L] "


puts "creating htaccess file.."
system("echo '#{htaccess}' > #{$config_map["HTACCESS"]}")

rsync = "rsync -a"
ssh = "ssh"

puts "#{ssh} #{$config_map["DEPLOYMENT_SERVER"]} 'cd #{$config_map["W3ID_REMOTE_LOCATION"]} && mkdir -p #{$config_map["URI_PATH_PREFIX"]}'"
system "#{ssh} #{$config_map["DEPLOYMENT_SERVER"]} 'cd #{$config_map["W3ID_REMOTE_LOCATION"]} && mkdir -p #{$config_map["URI_PATH_PREFIX"]}'"

puts "#{rsync} #{$config_map["W3ID_LOCAL_DIR"]} #{$config_map["W3ID_REMOTE_SSH"]}"
system "#{rsync} #{$config_map["W3ID_LOCAL_DIR"]} #{$config_map["W3ID_REMOTE_SSH"]}"