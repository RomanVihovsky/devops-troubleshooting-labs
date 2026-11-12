# A07: ClusterRole secret-reader bound to the group system:authenticated "for the backup tool"
kns backup
kx -n backup create serviceaccount backup-agent --dry-run=client -o yaml | ka -f -
kx create clusterrole secret-reader --verb=get,list,watch --resource=secrets --dry-run=client -o yaml | ka -f -
kx create clusterrolebinding secret-reader --clusterrole=secret-reader --group=system:authenticated --dry-run=client -o yaml | ka -f -
can_i bob list secrets -A || die "bob can't read secrets"
