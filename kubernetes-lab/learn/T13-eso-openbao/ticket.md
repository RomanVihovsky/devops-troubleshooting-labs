# T13 · ESO + OpenBao: kv-v2, a least-privilege role, a SecretStore with caProvider, rotation
**Learn** · secrets live in OpenBao, Kubernetes gets copies - with exactly the access it needs · ~45 min

OpenBao runs on k8s-gw (`https://bao.lab:8200`, TLS from the lab CA; `eval "$(./lab env)"` sets `BAO_ADDR`,
`BAO_CACERT` and a root `BAO_TOKEN`). The kubernetes auth method is already configured (ESO's own
ClusterSecretStore `openbao` uses role `eso`). Build a **namespaced** path for team `t13`:

1. Store the database credentials in kv-v2: `secret/t13/db` with `username=app` and a password of your choice.
2. A policy **`t13-read`** that can read `secret/t13/*` and **nothing else**.
3. A kubernetes-auth role **`t13`**: only the ServiceAccount `t13-reader` in namespace `t13`, policy
   `t13-read`, audience `openbao`.
4. In `t13`: the ServiceAccount `t13-reader`, a ConfigMap `lab-ca` with the lab CA (`$BAO_CACERT`), a
   **SecretStore** `openbao` that trusts that CA via **caProvider**, and an **ExternalSecret** `db-creds`
   (refresh every 15 s) that produces the Secret `db-creds` with `username` and `password`. Starters:
   `workspace/T13/`.
5. **Rotate**: put a new password into OpenBao and watch `db-creds` follow.

**Test**: SecretStore `openbao` Ready with caProvider; ExternalSecret Ready; `db-creds` holds OpenBao's
*current* password (rotated at least once); role `t13` is bound to `t13/t13-reader` with policy `t13-read`,
and that policy can read `secret/t13/db` but not `secret/shop`.
