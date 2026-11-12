dns_ips() {
  kx run "dns-probe-$RANDOM" -n ring --rm -i --restart=Never --quiet --image="$BUSYBOX_IMAGE" --labels="$LAB_LABEL=$LAB_ID" --command -- \
    sh -c 'nslookup -timeout=3 -type=a peers.ring.svc.cluster.local 2>/dev/null' 2>/dev/null | awk '/^Address: / { print $2 }' | sort
}
pod_ips() { kx -n ring get pods -l app=ring -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.status.podIP}{"\n"}{end}' | sort; }
three_peers() { local d; d=$(dns_ips); [ "$(echo "$d" | grep -c .)" = 3 ] && [ "$d" = "$(pod_ips)" ]; }
check_eventually 60 "peers.ring resolves to the 3 ring pod IPs" three_peers
check "ring still has 3 replicas" deploy_ready ring ring 3
verdict
