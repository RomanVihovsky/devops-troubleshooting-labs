sxi <<'S'
mkdir -p /srv/shop/assets
echo '<h1>Shop is open</h1><link rel="stylesheet" href="/assets/app.css">' > /srv/shop/index.html
echo 'body { font-family: sans-serif }' > /srv/shop/assets/app.css
chmod 644 /srv/shop/index.html
chmod 600 /srv/shop/assets/app.css                        # "security tuning"
cat > /etc/nginx/sites-enabled/default <<'A'
server {
    listen 80 default_server;
    root /srv/shop
    index index.html;
    location / { try_files $uri $uri/ =404; }
}
A
sed -i 's/^worker_processes .*/worker_processes 1;/' /etc/nginx/nginx.conf
mkdir -p /etc/systemd/system/nginx.service.d
cat > /etc/systemd/system/nginx.service.d/tuning.conf <<'A'
# Friday tuning: "fewer fds = less memory"
[Service]
LimitNOFILE=16
A
systemctl daemon-reload
systemctl restart nginx || true
S
