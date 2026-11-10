# L02: a TOML syntax error appended to containerd's config on k8s-w1 (missing "]"), containerd restarted
nx k8s-w1 "printf '%s\n' '' '# OPS-31: faster image pulls' \"[plugins.'io.containerd.cri.v1.images'\" '  max_concurrent_downloads = 10' >> /etc/containerd/config.toml && systemctl restart containerd; true" </dev/null
notready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != True ]; }
retry 180 notready || die "k8s-w1 stayed Ready"
