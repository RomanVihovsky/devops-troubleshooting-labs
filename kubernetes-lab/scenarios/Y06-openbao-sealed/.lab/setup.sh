# Y06: "maintenance" backed up /etc/openbao, then replaced the static seal key and restarted OpenBao: it stays sealed
remember y06_token "$(bx kv get -mount=secret -field=api_token shop)"
nx k8s-gw 'set -e; mkdir -p /var/backups/openbao
  tar -czf "/var/backups/openbao/etc-openbao-$(date -d yesterday +%F).tgz" -C / etc/openbao
  openssl rand -out /etc/openbao/unseal.key 32; chown openbao:openbao /etc/openbao/unseal.key; chmod 600 /etc/openbao/unseal.key
  systemctl restart openbao' </dev/null
sealed() { [ "$(bao_api sys/seal-status | jq -r .sealed)" = true ]; }
retry 60 sealed || die "OpenBao is not sealed"
kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s)" --overwrite >/dev/null
failing() { kx -n shop get externalsecret shop-secrets -o json | jq -e '[.status.conditions[]? | select(.type == "Ready" and .status == "False")] | length > 0' >/dev/null; }
retry 180 failing || die "shop-secrets still syncs"
