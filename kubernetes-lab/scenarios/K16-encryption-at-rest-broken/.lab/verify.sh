etcd_head() { nx "$CP" "etcdctl $ETCD_FLAGS get /registry/secrets/$1 --print-value-only 2>/dev/null | head -c 24" </dev/null 2>/dev/null; }
enc() { etcd_head "$1" | grep -aq '^k8s:enc:aescbc:v1:'; }
api_ok() { kx get --raw /readyz >/dev/null 2>&1; }
first_aescbc() {
  nx "$CP" 'f=$(grep -o -- "--encryption-provider-config=[^ \"]*" /etc/kubernetes/manifests/kube-apiserver.yaml | cut -d= -f2); [ -n "$f" ] && cat "$f"' </dev/null 2>/dev/null \
    | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin) or {}
r = [x for x in d.get("resources", []) if "secrets" in x.get("resources", [])]
sys.exit(0 if r and "aescbc" in r[0]["providers"][0] else 1)'
}
fresh() {
  local n="lab-k16-$RANDOM" r=1
  kx -n payments create secret generic "$n" --from-literal=x=y >/dev/null 2>&1 || return 1
  enc "payments/$n" && r=0
  kx -n payments delete secret "$n" >/dev/null 2>&1; return $r
}
check_eventually 240 "the API answers" api_ok
check "the API server's encryption config has aescbc first for Secrets" first_aescbc
check "a new Secret is stored aescbc-encrypted" fresh
check "the pre-existing payments/stripe-key is stored aescbc-encrypted" enc payments/stripe-key
check_eventually 180 "all nodes Ready" nodes_ready
verdict
