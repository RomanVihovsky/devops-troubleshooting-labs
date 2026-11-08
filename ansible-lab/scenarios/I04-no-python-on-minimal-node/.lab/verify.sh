marker() { nx "$1" "cat /etc/acme/node.txt" 2>/dev/null | grep -q "^$1 Debian 3\."; }
heals_new_node() {
  nx web1 "dpkg --purge --force-depends python3 python3-minimal python3.11 python3.11-minimal python3-apt >/dev/null 2>&1; rm -f /etc/acme/node.txt"
  applies site.yml && marker web1
}
check "app1 is configured by site.yml" marker app1
check "a node stripped of Python is bootstrapped and configured by site.yml alone" heals_new_node
check "site.yml converges" converged site.yml
verdict
