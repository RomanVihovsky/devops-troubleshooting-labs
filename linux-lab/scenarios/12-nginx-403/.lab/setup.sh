sxi <<'S'
mkdir -p /srv/www/shop
cat > /srv/www/shop/index.html <<'A'
<h1>Welcome to the Shop</h1>
A
chmod 644 /srv/www/shop/index.html; chmod 755 /srv/www/shop
cat > /etc/nginx/sites-enabled/default <<'A'
server {
    listen 80 default_server;
    root /srv/www/shop;
    index index.html;
    location / { try_files $uri $uri/ =404; }
}
A
chmod 0750 /srv/www            # "storage cleanup"
systemctl reload nginx
S
