# A04: namespace enforces PSA restricted; the pod template is privileged and sets nothing restricted needs
kns secure-apps
kx label namespace secure-apps pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/enforce-version=latest --overwrite >/dev/null
ka -f reporter.yaml
forbidden() { kx -n secure-apps get events -o jsonpath='{.items[*].message}' | grep -q 'violates PodSecurity'; }
retry 60 forbidden || die "no PodSecurity rejection"
