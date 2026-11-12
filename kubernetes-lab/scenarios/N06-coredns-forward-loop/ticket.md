# DNS down everywhere after the "local resolver" change
**INC-2606** · P1 · Reporter: on-call

Someone pointed CoreDNS's upstream at "the local resolver" this morning (ConfigMap `coredns` in
`kube-system`). Since then CoreDNS is in **CrashLoopBackOff** and no pod resolves anything - not even
`kubernetes.default`.

**Test**: CoreDNS is Ready; pods resolve cluster names, the lab zone (`git.lab`) and external names.
