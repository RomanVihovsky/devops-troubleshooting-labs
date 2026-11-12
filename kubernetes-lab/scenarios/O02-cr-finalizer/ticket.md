# kubectl delete database orders-db hangs
**INC-2589** · P4 · Reporter: team data

`kubectl -n dbs delete database orders-db` never returns and the object stays (with a deletion timestamp). The
database operator was replaced by a managed service last week; its controller is gone, the CRD stays (the
inventory database's object is still used for bookkeeping). The real database behind orders-db was already
dropped by the DBA.

**Test**: `orders-db` is gone; `inventory-db` still exists; the CRD `databases.example.com` still exists.
