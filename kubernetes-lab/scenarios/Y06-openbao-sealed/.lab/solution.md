# Y06 - an auto-unseal key that doesn't match the data

**Root cause**: this OpenBao auto-unseals with a **static seal**: `/etc/openbao/unseal.key` wraps the root key
stored with the data. The maintenance run "repaired" the key file by generating a new random key. At the
restart OpenBao couldn't decrypt its stored keys (*failed to unseal core: ... failed to decrypt keys from
storage*) and stayed **sealed**, retrying every 5 s. A sealed OpenBao answers health checks and nothing else.
ESO's logins failed, the store went NotReady, and no ExternalSecret could refresh.

**Diagnosis**
```
bao status                                           # Sealed true, Seal Type static
./lab node gw
sudo journalctl -u openbao --since -10min | grep -i unseal
sudo tar -tzvf /var/backups/openbao/etc-openbao-*.tgz
sudo cmp /etc/openbao/unseal.key <(sudo tar -xzOf /var/backups/openbao/etc-openbao-*.tgz etc/openbao/unseal.key)
```

**Fix**: the original key from the backup, then a restart. OpenBao unseals itself. Force an ESO refresh.

**Interview notes**
- Shamir unseal (key shares, `bao operator unseal` × threshold) vs auto-unseal (cloud KMS, HSM, Transit, or
  a static key here). With auto-unseal, **recovery keys can't unseal**: they only authorize some operations.
  Lose the seal key and the data is gone.
- The seal key is the most important backup of the whole secret store. Keep it separate from the data
  backup, and out of reach of config-management "repairs" (mark it unmanaged, alert on changes).
- A sealed store fails slowly: existing Kubernetes Secrets keep working until something rotates or a new
  namespace needs one. Alert on `vault_core_unsealed == 0` / OpenBao's seal-status, not just on the process.
