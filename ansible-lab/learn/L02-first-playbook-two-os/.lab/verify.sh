page_ok() { http_get "http://$1:8080/" | grep -qE "Hello from $1 running $2 [0-9]+"; }
check "web1 answers on 8080: Hello from web1 running Debian 12" page_ok web1 Debian
check "web2 answers on 8080: Hello from web2 running Rocky 9" page_ok web2 Rocky
check "nginx is enabled on both" eval 'nx web1 "systemctl is-enabled nginx" && nx web2 "systemctl is-enabled nginx"'
check "site.yml converges (check mode: no changes)" converged site.yml
verdict
