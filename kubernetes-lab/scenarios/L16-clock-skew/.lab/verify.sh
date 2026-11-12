w1_ready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
chrony_on() { [ "$(nx k8s-w1 'systemctl is-enabled chrony; systemctl is-active chrony' </dev/null | tr '\n' ' ')" = "enabled active " ]; }
synced() {
  local out off; out=$(nx k8s-w1 'chronyc -n tracking' </dev/null) || return 1
  grep -q '^Reference ID.*(192.168.56.20)' <<<"$out" || return 1
  off=$(awk '/^System time/ { print $4 }' <<<"$out")
  awk -v o="$off" 'BEGIN { exit !(o + 0 < 1.0) }'
}
same_cert() { [ "$(nx k8s-w1 'openssl x509 -noout -fingerprint -sha256 -in /var/lib/kubelet/pki/kubelet-client-current.pem' </dev/null)" = "$(recall l16_cert)" ]; }
check "chrony enabled and active on k8s-w1" chrony_on
check_eventually 60 "k8s-w1 synchronised to 192.168.56.20, offset < 1 s" synced
check_eventually 180 "k8s-w1 Ready" w1_ready
check "the kubelet's client certificate is the original one" same_cert
verdict
