sx "sed -i 's#root /srv/shop\$#root /srv/shop;#' /etc/nginx/sites-enabled/default
    chmod 644 /srv/shop/assets/app.css
    rm -f /etc/systemd/system/nginx.service.d/tuning.conf
    systemctl daemon-reload && nginx -t && systemctl restart nginx"
