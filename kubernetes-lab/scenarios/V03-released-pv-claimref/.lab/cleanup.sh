# V03: the PV is cluster-scoped (and maybe re-created by the student); the data dir lives on k8s-gw
kx delete namespace archive --ignore-not-found --wait=false >/dev/null 2>&1
kx wait --for=delete namespace/archive --timeout=90s >/dev/null 2>&1
kx delete pv orders-archive --ignore-not-found >/dev/null 2>&1
nx k8s-gw 'rm -rf /srv/nfs/lab-v03-archive' </dev/null
true
