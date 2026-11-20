default_kept() { [ "$(kx get ippools.crd.projectcalico.org default-ipv4-ippool -o jsonpath='{.spec.cidr} {.spec.blockSize}' 2>/dev/null)" = "$(recall x08_default)" ]; }
not_default() {
  local a; a=$(kx get ns batch -o jsonpath='{.metadata.annotations.cni\.projectcalico\.org/ipv4pools}' 2>/dev/null)
  [ -n "$a" ] && ! grep -q default-ipv4-ippool <<<"$a"
}
batch_ips() {
  kx -n batch get pods -l app=crunch --field-selector=status.phase=Running -o jsonpath='{.items[*].status.podIP}' | python3 -c '
import ipaddress, sys
ips = sys.stdin.read().split()
sys.exit(0 if len(ips) == 12 and all(ipaddress.ip_address(i) in ipaddress.ip_network("10.250.0.0/16") for i in ips) else 1)'
}
check_eventually 180 "crunch: 12 Ready pods" deploy_ready batch crunch 12
check "all 12 pod IPs come from 10.250.0.0/16" batch_ips
check "namespace batch is pinned to batch pools, not the default pool" not_default
check "the default pool is unchanged" default_kept
verdict
