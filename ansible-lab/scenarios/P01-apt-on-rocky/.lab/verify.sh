page() { [ "$(http_get "http://$1/")" = "ACME on $1 ($2)" ]; }
check "site.yml deploys to both nodes" applies site.yml
check "web1 serves the home page (Debian, apache2)" eval 'page web1 Debian && svc_active web1 apache2'
check "web2 serves the home page (RedHat, httpd)" eval 'page web2 RedHat && svc_active web2 httpd'
check "one role for both OS families" eval '[ "$(ls -d "$CI"/roles/*/ | wc -l)" = 1 ]'
check "site.yml converges" converged site.yml
verdict
