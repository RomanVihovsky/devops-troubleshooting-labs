sx "sed -i 's#/etc/ssl/lab/srv.key;#/etc/ssl/lab/srv-2026.key;#' /etc/nginx/sites-enabled/shop-tls && nginx -t && systemctl reload nginx"
