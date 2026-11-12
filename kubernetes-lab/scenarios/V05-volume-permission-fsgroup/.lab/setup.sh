# V05: an NFS volume (root-owned 755) for a pod running as uid 1000, no fsGroup; the namespace is PSA restricted
kns uploads
kx label namespace uploads pod-security.kubernetes.io/enforce=restricted --overwrite >/dev/null
ka -f uploads.yaml
crashing() { crashlooping uploads app=uploads; }
retry 180 crashing || die "uploads did not crash"
kx -n uploads logs deploy/uploads 2>/dev/null | grep -qi 'permission denied' || kx -n uploads logs deploy/uploads --previous 2>/dev/null | grep -qi 'permission denied' \
  || die "the crash is not 'permission denied'"
