## Hint 1
`bao status` (after `eval "$(./lab env)"`) and, on the gateway (`./lab node gw`),
`sudo journalctl -u openbao --since -10min`. What does OpenBao try at start-up, and what fails?

## Hint 2
This OpenBao unseals itself with a **static key** (`seal "static"` in `/etc/openbao/openbao.hcl`, key file
`/etc/openbao/unseal.key`). "failed to decrypt keys from storage" = the key file is not the one the data was
sealed with. Compare it with the backup: `sudo tar -tzvf /var/backups/openbao/*.tgz`.

## Hint 3
`sudo tar -xzf /var/backups/openbao/etc-openbao-*.tgz -C / etc/openbao/unseal.key && sudo systemctl restart
openbao`, then on the desktop `kubectl -n shop annotate externalsecret shop-secrets force-sync=$(date +%s) --overwrite`.
