# P03 - the right image for the wrong CPU

**Root cause**: `labapp:1.6` was pushed from an arm64 laptop as a **single-platform** manifest for
`linux/arm64`. A plain manifest (no image index) tells the runtime nothing to choose from, so containerd
pulled it and the kernel refused the arm64 binary: *exec format error*.

**Diagnosis**
```
kubectl -n analytics logs deploy/etl                        # exec /usr/local/bin/python3: exec format error
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}'; echo   # amd64
./lab node gw
crane config --insecure registry.lab:5000/lab/labapp:1.6 | jq '{os, architecture}'
crane manifest --insecure registry.lab:5000/lab/labapp:1.6 | jq .mediaType     # a manifest, not an index
```

**Fix**: back to `1.4` (amd64) until the build publishes amd64 or a multi-arch index
(`docker buildx build --platform linux/amd64,linux/arm64 --push`).

**Interview notes**
- An image **index** (manifest list) maps platforms to manifests, and the runtime picks its own. A
  single-arch manifest under a tag is taken as-is.
- Mixed clusters (Graviton/Ampere + x86): label `kubernetes.io/arch` and use nodeAffinity, or build
  multi-arch.
- `exec format error` also appears for scripts without a shebang (`#!/bin/sh` missing) or with CRLF line
  endings. Check the binary/arch first, then the file.
- Builds belong in CI with a pinned platform. A laptop push under a release tag is a supply-chain smell:
  sign images, and admit only signed ones.
