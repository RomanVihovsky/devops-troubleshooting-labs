# archive's volume is full and won't grow
**INC-2469** · P2 · Reporter: team archive

`archive-data` (1Gi, StorageClass `nfs-standard`) is full. We changed `storage: 1Gi` to `2Gi` in
`workspace/V07/archive.yaml` and applied: *only dynamically provisioned pvc can be resized and the storageclass
that provisions the pvc must support resize*. It IS dynamically provisioned. Grow it **in place** - the data
must stay (no new PVC with a copy).

**Test**: PVC `archive-data` (the same claim, the same volume) reports a capacity of 2Gi; the file the app wrote
before the resize is still there; `archive` Ready.
