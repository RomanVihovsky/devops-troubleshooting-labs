fw_kept() {
  local t; t=$(nx k8s-w3 'nft list table inet host_firewall 2>/dev/null' </dev/null)
  grep -q 'drop' <<<"$t" && grep -q 'udp dport' <<<"$t"
}
mesh() { ns_matrix meshcheck app=echo; }
ds_ready() { [ "$(kx -n meshcheck get ds echo -o jsonpath='{.status.numberReady}' 2>/dev/null)" = 3 ]; }
check_eventually 90 "meshcheck runs on all 3 workers" ds_ready
check_eventually 60 "every meshcheck pod reaches every other one across nodes" mesh
check "w3's host_firewall table still drops unknown UDP" fw_kept
verdict
