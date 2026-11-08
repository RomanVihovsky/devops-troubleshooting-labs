nx db1 "mkdir -p /var/lib/acme && touch /var/lib/acme/migrations.log"
ap site.yml
retry 30 http_get http://lb1/version.txt
