# thumbs pods evicted every few minutes
**INC-2463** · P2 · Reporter: team media

`thumbs` builds a ~300 MiB disk cache at start (`DISK_CACHE_MB=300`, in `CACHE_DIR=/tmp/cache`). Since the "resource
limits for everyone" change, its pods are evicted again and again: *Pod ephemeral local storage usage exceeds
the total limit of containers 100Mi*. The cache size stays as it is (it's what makes thumbs fast). Give the cache
a proper home: a volume with an explicit size.

**Test**: `thumbs` has 2 Ready pods that stay up 60 s with no new evictions; `DISK_CACHE_MB` is still 300;
`/tmp/cache` is a volume with a size: an `emptyDir` with a `sizeLimit` of at least 300Mi, or a PVC.
