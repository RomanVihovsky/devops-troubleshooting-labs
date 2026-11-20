# DR: x509 errors everywhere, and prod was deleted during the panic
**INC-2950** · P1 · Reporter: incident commander

Timeline: the nightly etcd backup ran (`/var/backups/etcd/nightly.db` on `k8s-cp1`). An hour later a "certificate
test" renewed the API server certificate on `k8s-cp1` with a lifetime of a few minutes - it has expired, `kubectl`
answers *x509: certificate has expired*. In between, someone ran a cleanup script that deleted namespace `prod`
(`ledger`, its PVC on the `nfs-retain` class, its config). Bring the cluster back: a normal one-year API server
certificate, and `prod` exactly as in the backup. The ledger's data on its volume must be the same as before.

**Test**: the API server certificate on cp1 is valid for more than 300 days and the API answers; `prod`, `ledger` and
PVC `ledger-data` are back with their original UIDs; `ledger` is Ready and serves the same balance as before;
etcd runs from restored data; all nodes are Ready.
