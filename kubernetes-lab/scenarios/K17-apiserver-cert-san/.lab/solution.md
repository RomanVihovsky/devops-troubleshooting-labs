# K17 - an API server certificate without the load balancer's IP

**Root cause**: the "tidy-up" removed `apiServer.certSANs` from `kube-system/kubeadm-config`, and the API server
certificate was then re-issued from that configuration. kubeadm always adds the node name, the advertise
address (192.168.56.21), the Service IP (10.96.0.1), the `kubernetes.default...` names and the
`controlPlaneEndpoint` host (`k8s-api.lab`). That is why the nodes, which use `k8s-api.lab:6443`, still
verified it. The load balancer's **IP** 192.168.56.20, which the desktops' kubeconfig uses, came only from
`certSANs`.

**Diagnosis**
```
openssl s_client -connect 192.168.56.20:6443 </dev/null 2>/dev/null | openssl x509 -noout -ext subjectAltName
./lab node cp1
sudo kubectl --kubeconfig /etc/kubernetes/admin.conf -n kube-system get cm kubeadm-config -o yaml | grep -A5 apiServer
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates -ext subjectAltName
```

**Fix** (on cp1): `certSANs` back into the ConfigMap; one kubeadm config file (InitConfiguration from
`/etc/kubernetes/kubeadm/init.yaml` + that ClusterConfiguration); remove `apiserver.crt/key`;
`kubeadm init phase certs apiserver --config <file>`; restart the kube-apiserver container. (`kubeadm certs
renew apiserver` would keep the SANs of the *current* cert, so it can't add a missing one.)

**Interview notes**
- Every name and IP that clients dial must be in the SANs: the LB IP *and* its DNS name, every control-plane
  node, the in-cluster Service IP. Add any new entry point (VIP, NAT address) to `certSANs` **first**.
- `kubeadm-config` is what `kubeadm upgrade` and `kubeadm init phase ...` read. A fix made only to the
  certificate disappears at the next upgrade/renewal; a fix made only to the ConfigMap doesn't reach the
  running cert.
- Never answer x509 with `--insecure-skip-tls-verify`; compare the SANs (`openssl ... -ext subjectAltName`)
  with the URL you use.
