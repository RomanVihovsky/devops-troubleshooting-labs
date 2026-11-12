# web-N.web.kv.svc.cluster.local -> web-N's IP, for N = 0..2 (one probe pod, FQDNs: see busybox nslookup in FAULTS)
records() {
  local want got
  want=$(for i in 0 1 2; do echo "$i $(kx -n kv get pod "web-$i" -o jsonpath='{.status.podIP}')"; done)
  got=$(kx -n kv run "lab-probe-$RANDOM" --rm -i --restart=Never --quiet --image="$BUSYBOX_IMAGE" --labels="$LAB_LABEL=$LAB_ID" --command -- \
    sh -c 'for i in 0 1 2; do echo "$i $(nslookup -type=a web-$i.web.kv.svc.cluster.local 2>/dev/null | awk "/^Address: /{print \$2}" | tail -1)"; done' 2>/dev/null)
  [ "$want" = "$got" ]
}
check_eventually 90 "web-0/1/2.web.kv.svc.cluster.local resolve to their pods" records
check "Service web-svc still answers" http_ok kv http://web-svc.kv.svc:8080/
verdict
