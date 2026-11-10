# wiki can't get a volume since the storage "cleanup"
**INC-2702** · P2 · Reporter: wiki team

The platform team "cleaned up StorageClass annotations" yesterday. Our new `wiki` (namespace `wiki`,
`workspace/V02/wiki.yaml`, no storage class on purpose: "use the cluster default") has a PVC stuck
**Pending**. Fix the cluster, not our manifest - other teams rely on the default too.

**Test**: the cluster has exactly one default StorageClass; `wiki-data` is Bound and wiki runs; the wiki
PVC still names no class in its manifest.
