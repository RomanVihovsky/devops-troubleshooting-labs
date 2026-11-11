# the "maintenance" backup on gw (not part of the gw golden); openbao: true restores /etc/openbao + the data
nx k8s-gw 'rm -rf /var/backups/openbao' </dev/null
kx annotate clustersecretstore openbao force-sync- >/dev/null 2>&1
true
