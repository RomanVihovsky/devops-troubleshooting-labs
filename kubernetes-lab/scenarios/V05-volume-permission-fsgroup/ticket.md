# uploads crash-loops on its new NFS volume
**INC-2466** · P2 · Reporter: team uploads

We moved `uploads` to a shared volume (StorageClass `nfs`, `workspace/V05/uploads.yaml`). It now exits at start:
*DATA_DIR /data is not writable: permission denied*. It runs as user 1000, and the namespace enforces the
**restricted** Pod Security level, so no root containers (no `chown` init container as root either).

**Test**: `uploads` has 2 Ready pods that can write to `/data` (a value written through one pod can be read back
through the other - shared volume); the pods still run as user 1000 (non-root); the namespace stays `restricted`.
