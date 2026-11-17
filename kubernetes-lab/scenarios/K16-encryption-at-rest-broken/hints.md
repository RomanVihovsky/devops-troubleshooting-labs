## Hint 1
No API: `./lab node cp1`, `crictl ps -a --name kube-apiserver`, `crictl logs <id> 2>&1 | tail`. Fix one error, then
look at the logs again - there may be more than one.

## Hint 2
The container sees only what's mounted: the flag points at `/etc/kubernetes/enc/` - is that directory a `hostPath`
volume in the manifest? And `aescbc` accepts only 16, 24 or 32-byte keys: `grep secret: enc.yaml | awk '{print $NF}' | base64 -d | wc -c`.

## Hint 3
Add a hostPath volume + mount for `/etc/kubernetes/enc` (readOnly), replace the key with
`head -c 32 /dev/urandom | base64`, wait for the API, then rewrite all Secrets so they're stored encrypted:
`kubectl get secrets -A -o json | kubectl replace -f -`.
