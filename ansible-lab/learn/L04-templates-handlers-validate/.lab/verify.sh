balances() {
  local seen
  seen=$(for i in 1 2 3 4 5 6; do http_get http://lb1/; done | sort -u | tr '\n' ' ')
  [ "$seen" = "web1 web2 " ]
}
lists_all() { nx lb1 "grep -cE '^\s*server (web1|web2) ' /etc/haproxy/haproxy.cfg" | grep -qx 2; }
validate_protects() {
  local before after
  before=$(nx lb1 "md5sum /etc/haproxy/haproxy.cfg")
  ! ap_json site.yml -e haproxy_balance=fastest || return 1
  after=$(nx lb1 "md5sum /etc/haproxy/haproxy.cfg")
  [ "$before" = "$after" ] && svc_active lb1 haproxy && out_has 'failed to validate'
}
check_eventually 10 "lb1 balances across web1 and web2" balances
check "the config has one server line per web host" lists_all
check "an invalid value is rejected by validate, live config untouched" validate_protects
check "site.yml converges" converged site.yml
verdict
