## Hint 1
`./lab node cp1`, `kubeadm certs check-expiration` (it may need `--config`, see below) and
`openssl x509 -noout -enddate -in /etc/kubernetes/pki/apiserver.crt`. Where did kubeadm take the short lifetime from?

## Hint 2
kubeadm v1beta4 has `certificateValidityPeriod` in **ClusterConfiguration** (stored in ConfigMap
`kube-system/kubeadm-config`). With the API down, give kubeadm the configuration as a file: `/etc/kubernetes/kubeadm/init.yaml`
plus a ClusterConfiguration **without** the short value.

## Hint 3
`kubeadm certs renew all --config <file>`, restart the four control-plane static pods (move their manifests out and
back, or change an annotation), wait for the API, then remove `certificateValidityPeriod` from the kubeadm-config
ConfigMap as well.
