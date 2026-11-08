node_json() { nx "$1" "cat /etc/acme/node.json" | jq -e "$2" >/dev/null; }
no_inject_deprecation() {
  local out; out=$(ctl_ci "unset ANSIBLE_INJECT_FACT_VARS; ansible-playbook site.yml --check 2>&1")
  echo "$out" | grep 'INJECT_FACTS_AS_VARS' >> "$VERIFY_LOG" && return 1
  echo "$out" | grep -q 'failed=0'
}
check "site.yml deploys with fact injection off" applies site.yml
check "web1 record: web1, Debian 12, sudo" node_json web1 '.host == "web1" and .os == "Debian 12" and .family == "Debian" and .admin_group == "sudo"'
check "web2 record: web2, Rocky 9, wheel" node_json web2 '.host == "web2" and .os == "Rocky 9" and .family == "RedHat" and .admin_group == "wheel"'
check "records carry the real Python version and CPU count" eval 'node_json web1 "(.python | test(\"^3\\\\.\")) and .cpus >= 1" && node_json web2 "(.python | test(\"^3\\\\.\")) and .cpus >= 1"'
check "no INJECT_FACTS_AS_VARS deprecation (old default)" no_inject_deprecation
check "site.yml converges" converged site.yml
verdict
