check "site.yml deploys" applies site.yml
check "web1 motd: web1, Debian 12, production" eval 'nx web1 "grep -q \"Welcome to web1 (Debian 12) - production\" /etc/motd"'
check "web2 motd: web2, Rocky 9, production" eval 'nx web2 "grep -q \"Welcome to web2 (Rocky 9) - production\" /etc/motd"'
check "no template code left in /etc/motd" eval 'nx web1 "! grep -qE \"[{][{]|[{]%\" /etc/motd" && nx web2 "! grep -qE \"[{][{]|[{]%\" /etc/motd"'
check "site.yml converges" converged site.yml
verdict
