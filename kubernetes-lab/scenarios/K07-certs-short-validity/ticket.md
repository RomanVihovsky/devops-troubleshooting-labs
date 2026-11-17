# "x509: certificate has expired" - the certificates were renewed minutes ago
**INC-2844** · P1 · Reporter: on-call

To test our expiry alerting, someone set a short certificate lifetime in the cluster's kubeadm configuration, ran
`kubeadm certs renew all` on `k8s-cp1` and restarted the control plane. A few minutes later everything broke:
`kubectl` says *x509: certificate has expired or is not yet valid*, the control-plane components can't talk to each
other. The cluster CA itself is fine. Give the control plane normal one-year certificates again, and make sure the
next renewal or upgrade doesn't bring the short lifetime back.

**Test**: every control-plane certificate and kubeconfig on `k8s-cp1` is valid for more than 300 days; the kubeadm
configuration in the cluster has no short `certificateValidityPeriod`; the API answers and all nodes are Ready.
