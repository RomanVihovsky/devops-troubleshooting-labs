# K07 - kubeadm renewed everything with a 4-minute lifetime

**Root cause**: `certificateValidityPeriod: 4m0s` was added to the ClusterConfiguration (ConfigMap
`kube-system/kubeadm-config`, kubeadm v1beta4). `kubeadm certs renew all` honours it, so every control-plane leaf
certificate - API server serving, apiserver -> etcd and -> kubelet clients, etcd server/peer, front-proxy, and the
embedded client certs of admin/controller-manager/scheduler kubeconfigs - got a 4-minute life. The CA has its own
`caCertificateValidityPeriod` and is fine. After 4 minutes the API server can't authenticate to etcd and clients
reject its expired serving certificate.

**Diagnosis** (on `k8s-cp1`)
```
openssl x509 -noout -dates -in /etc/kubernetes/pki/apiserver.crt
crictl logs $(crictl ps -a --name kube-apiserver -q | head -1) 2>&1 | grep -i x509 | tail -3
grep -n certificateValidityPeriod /etc/kubernetes/kubeadm/*.yaml ; # and the ConfigMap, once the API is back
```

**Fix**:
1. a config file without the short value (`/etc/kubernetes/kubeadm/init.yaml` holds the cluster's original
   Init/ClusterConfiguration): `kubeadm certs renew all --config /var/tmp/fix.yaml`;
2. restart the four static pods (change an annotation or move the manifests out and back);
3. once the API answers: remove `certificateValidityPeriod` from the kubeadm-config ConfigMap - otherwise the next
   `kubeadm upgrade` (which renews certificates) brings the 4 minutes back.

**Interview notes**
- `kubeadm certs check-expiration`; `kubeadm upgrade apply` renews leaf certs automatically (yearly upgrades =
  never expiring certs).
- The kubelet's client cert isn't kubeadm's: it rotates via CSRs (`rotateCertificates: true`).
- Testing expiry alerts belongs in a throwaway cluster - or alert on `apiserver_client_certificate_expiration_seconds`
  and certificate metrics instead.
