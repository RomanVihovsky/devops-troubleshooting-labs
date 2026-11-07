cat > "$WORK_DIR/nginx.conf" <<'NGINX'
resolver 127.0.0.11 valid=2s ipv6=off;

server {
    listen 80;
    location / {
        set $upstream http://web:8000;
        proxy_pass $upstream;
        proxy_connect_timeout 2s;
        proxy_read_timeout 5s;
    }
}
NGINX
ws_sed 's#^    file: ./nginx.conf#    name: app_nginx_conf_v2\n    file: ./nginx.conf#'
deploy_stack
sleep 3
retry 90 svc_converged app_proxy
retry 60 all_nodes_http / 'Hello' 1
