# V10 - emptyDir is scratch space

**Root cause**: `/data` is an `emptyDir`: created with the pod, deleted with the pod (it survives
container restarts, not pod replacement).

**Fix**: a PVC at `/data` (+ `strategy: Recreate`, or a StatefulSet, so a new pod can attach an RWO volume).

**Interview notes**
- emptyDir = caches, scratch, sharing files between containers of one pod; `medium: Memory` counts against
  the memory limit; `sizeLimit` against ephemeral storage (P15).
- RWO + RollingUpdate: the new pod may land on another node and wait for the volume - Recreate or a
  StatefulSet avoids the deadlock.
