ka -f - <<'YML'
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: batch-pool-2
spec:
  cidr: 10.250.1.0/26
  blockSize: 26
  ipipMode: Never
  vxlanMode: Always
  natOutgoing: true
  nodeSelector: all()
  allowedUses: [Workload]
YML
kx annotate namespace batch --overwrite 'cni.projectcalico.org/ipv4pools=["batch-pool","batch-pool-2"]' >/dev/null
# the annotation is read at sandbox creation: replace the pods that are stuck
for p in $(kx -n batch get pods -l app=crunch --field-selector=status.phase=Pending -o name); do kx -n batch delete "$p" --wait=false >/dev/null; done
retry 180 deploy_ready batch crunch 12 || true
