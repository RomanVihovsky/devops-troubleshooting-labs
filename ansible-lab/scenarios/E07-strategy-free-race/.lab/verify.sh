LIMIT=21
fast_deploy() {
  local t0 rc=0 n
  for n in web1 web2 web3; do nx "$n" "rm -f /etc/shop-cluster.conf"; done
  t0=$SECONDS
  applies deploy.yml || rc=$?
  echo "deploy took $((SECONDS - t0)) s (limit $LIMIT s)" >> "$VERIFY_LOG"
  [ $rc -eq 0 ] && [ $((SECONDS - t0)) -lt $LIMIT ]
}
members_ok() {
  local n m id
  for n in web1 web2 web3; do
    for m in web1 web2 web3; do
      id=$(nx "$m" "cat /var/lib/shop/node_id") || return 1
      [ -n "$id" ] && nx "$n" "grep -qx 'member $m $id' /etc/shop-cluster.conf" || return 1
    done
  done
}
check "deploy.yml applies on all nodes, in under $LIMIT s" fast_deploy
check "every node's /etc/shop-cluster.conf lists web1, web2, web3 with their node IDs" members_ok
check "deploy.yml converges (check mode: no changes)" converged deploy.yml
verdict
