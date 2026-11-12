# archive data volume won't bind to the new claim
**INC-2703** · P2 · Reporter: records team

The PersistentVolume `orders-archive` (NFS, reclaim policy Retain) holds 10 years of order archives. We
moved the app: the old claim was deleted, the new claim `archive` (namespace `archive`,
`workspace/V03/archive.yaml`) asks for that exact volume - and stays **Pending**. The data must survive;
don't create a new volume.

**Test**: `archive` is Bound to `orders-archive` (the same PV object), the reader pod runs and sees the
archive (`/data/index.txt`).
