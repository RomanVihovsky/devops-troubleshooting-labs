sxi <<'S'
set -e
mkdir -p /etc/ssl/lab/ca/newcerts && cd /etc/ssl/lab
touch ca/index.txt; echo 1000 > ca/serial
cat > ca/ca.cnf <<'A'
[ ca ]
default_ca = lab
[ lab ]
dir            = /etc/ssl/lab/ca
database       = $dir/index.txt
new_certs_dir  = $dir/newcerts
serial         = $dir/serial
default_md     = sha256
policy         = pol
copy_extensions = copy
unique_subject = no
[ pol ]
commonName = supplied
A
q() { "$@" >/dev/null 2>&1; }
q openssl req -x509 -newkey rsa:2048 -nodes -keyout ca/ca.key -out ca/ca.crt -days 3650 -subj "/CN=Lab Root CA"
# last year's certificate (expired)
q openssl req -newkey rsa:2048 -nodes -keyout srv.key -out old.csr -subj "/CN=srv.lab" -addext "subjectAltName=DNS:srv.lab"
q openssl ca -batch -config ca/ca.cnf -cert ca/ca.crt -keyfile ca/ca.key -in old.csr -out srv.crt -startdate 20250101000000Z -enddate 20260101000000Z
cat > /etc/nginx/sites-enabled/shop-tls <<'A'
server {
    listen 443 ssl;
    server_name srv.lab;
    ssl_certificate     /etc/ssl/lab/srv.crt;
    ssl_certificate_key /etc/ssl/lab/srv.key;
    location / { default_type text/plain; return 200 "secure shop OK\n"; }
}
A
systemctl reload nginx
# the renewal job: new key + new cert, cert written over the old path, key to a new name
q openssl req -newkey rsa:2048 -nodes -keyout srv-2026.key -out new.csr -subj "/CN=srv.lab" -addext "subjectAltName=DNS:srv.lab"
q openssl ca -batch -config ca/ca.cnf -cert ca/ca.crt -keyfile ca/ca.key -in new.csr -out srv.crt -days 365
chmod 600 srv.key srv-2026.key ca/ca.key
rm -f old.csr new.csr
S
docker exec lnx-srv cat /etc/ssl/lab/ca/ca.crt | docker exec -i lnx-client sh -c \
  'cat > /usr/local/share/ca-certificates/lab-root-ca.crt && update-ca-certificates >/dev/null 2>&1'
