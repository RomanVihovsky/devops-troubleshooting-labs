# billing's first sync never finishes
**INC-2340** · P3 · Reporter: team billing

Our new app `billing` was merged an hour ago. Argo CD has been showing *Syncing* ever since: "waiting for
completion of hook batch/Job/billing-migrate". The schema migration must run **before** the new version
starts (it's a PreSync hook on purpose - don't make it PostSync). Its pod never starts. Get the first sync
through, and make sure the next release won't hang the same way.

**Test**: billing is Synced + Healthy and its last sync Succeeded with the migration as a **PreSync** hook that
Succeeded; a fresh sync (the test triggers one) also Succeeds; the Secret `db-creds` comes from its
SealedSecret (not made by hand); billing pods are Ready.
