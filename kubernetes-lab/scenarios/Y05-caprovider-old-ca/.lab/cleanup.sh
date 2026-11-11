# lab-ca (cluster add-on state, not in the scenario's namespaces) back to the current CA
eso_store_restore || warn "Y05: lab-ca / store not restored"
kx annotate clustersecretstore openbao force-sync- >/dev/null 2>&1
kx -n shop annotate externalsecret shop-secrets force-sync- >/dev/null 2>&1
true
