motd() { nx "$1" "cat /etc/motd"; }
check "web1: env prod, owner Platform, contact web-oncall" eval 'motd web1 | grep -qx "web1 | env: prod | owner: Platform | contact: web-oncall@acme.example"'
check "web2: env staging, owner Team Rocky, contact web-oncall" eval 'motd web2 | grep -qx "web2 | env: staging | owner: Team Rocky | contact: web-oncall@acme.example"'
check "the role is unchanged (configured from the inventory)" untouched roles
check "site.yml converges" converged site.yml
verdict
