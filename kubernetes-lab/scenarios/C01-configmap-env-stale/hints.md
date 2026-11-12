## Hint 1
`kubectl -n promo exec deploy/promo -- printenv GREETING` - what does the running process see? How does the
Deployment pass the ConfigMap to the container?

## Hint 2
Environment variables from a ConfigMap (`envFrom`/`configMapKeyRef`) are copied into the container when it
**starts**. Changing the ConfigMap doesn't touch running containers.

## Hint 3
`kubectl -n promo rollout restart deploy/promo`. To make this automatic, change something in the pod template
when the config changes (a checksum annotation from your deploy tool, Helm's `checksum/config`, or Reloader).
