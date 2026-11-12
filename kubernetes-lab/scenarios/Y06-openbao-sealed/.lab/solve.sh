nx k8s-gw 'tar -xzf "$(ls /var/backups/openbao/etc-openbao-*.tgz | tail -1)" -C / etc/openbao/unseal.key && systemctl restart openbao' </dev/null
retry 60 bao_unsealed || true
kx annotate clustersecretstore openbao force-sync="$(date +%s)" --overwrite >/dev/null
kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s)" --overwrite >/dev/null
retry 120 store_ready || true
