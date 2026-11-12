# inventory can't be deployed: "Unsupported value: status.podIp"
**INC-2448** · P3 · Reporter: team inventory

Our service registers itself with its pod IP and sizes its cache from its memory limit, both via the Downward
API (`POD_IP`, `MEMORY_LIMIT_MB`). `kubectl apply -f workspace/C08/inventory.yaml` is rejected. The service must
run with a **256Mi** memory limit, and `MEMORY_LIMIT_MB` must say so.

**Test**: `inventory` has 2 Ready pods; in each pod `POD_IP` equals that pod's IP and `MEMORY_LIMIT_MB` is `256`;
both still come from the Downward API (`fieldRef` / `resourceFieldRef`).
