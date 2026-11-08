NODES="app1 app2 web1 web2"
on() {   # on <release>: nodes whose current release is <release>
  local n
  for n in $NODES; do [ "$(nx "$n" 'readlink /opt/shop/current')" = "/opt/shop/$1" ] && echo "$n"; done | xargs
}
everywhere() {   # a healthy release reaches all four nodes and serves
  local n
  applies deploy.yml -e shop_release=4.2.0 || return 1
  for n in $NODES; do http_get "http://$n:8090/" | grep -q 'shop 4.2.0' || return 1; done
}
bad() { ap_json deploy.yml -e shop_release="$1" || true; echo "nodes on $1: [$(on "$1")]" >> "$VERIFY_LOG"; }
only_canary() { [ "$(on 5.0.0)" = web2 ]; }
stopped_after_first_failing_batch() { local b; b=" $(on 5.0.1) "; [[ $b == *" web2 "* && $b != *" web1 "* ]]; }

check "4.2.0 reaches all four nodes" everywhere
bad 5.0.0
check "5.0.0 (fails on Rocky): only the canary web2 got it, the run stopped" only_canary
check "4.2.0 reaches all four nodes again" everywhere
bad 5.0.1
check "5.0.1 (fails on Debian): canary passed, the first failing batch stopped the run - web1 never got it" stopped_after_first_failing_batch
check "4.2.0 reaches all four nodes again" everywhere
check "deploy.yml converges (check mode, 4.2.0: no changes)" converged deploy.yml -e shop_release=4.2.0
verdict
