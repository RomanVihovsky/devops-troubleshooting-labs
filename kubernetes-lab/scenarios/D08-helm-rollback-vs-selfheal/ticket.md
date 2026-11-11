# ledger 1.5 crash-loops, and the rollback didn't stick
**INC-2331** · P2 · Reporter: on-call (night shift)

`ledger` 1.5 went out at 02:10 and its new pods crash-loop. I did what our runbook says: `helm history ledger
-n ledger`, then `helm rollback ledger 1 -n ledger` (it complained about conflicts, so I added
`--force-conflicts`). It worked - for about a minute. Now 1.5 is back. ledger moved to Argo CD last week;
maybe that's related? Roll back properly, and make sure nobody can "helm rollback" this app by mistake again.

**Test**: ledger answers 200 inside the cluster on a version that starts; the Argo CD app ledger is Synced +
Healthy with no sync operation for 60 s; `main` no longer deploys 1.5 for ledger; auto-sync + self-heal stay on;
no Helm release records (`sh.helm.release.v1.ledger.*`) are left in namespace ledger.
