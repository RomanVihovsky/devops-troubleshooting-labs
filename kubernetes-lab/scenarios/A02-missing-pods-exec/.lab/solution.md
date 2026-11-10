# A02 - pods/exec is a separate permission

**Root cause**: the Role allows `pods` and `pods/log`, not `pods/exec`. `kubectl exec` is a `create` on the
`pods/exec` subresource (older clients/websockets also need `get`).

**Fix**: add `pods/exec` with `create` (+ `get`).

**Interview notes**
- Subresources: `pods/exec`, `pods/attach`, `pods/portforward`, `pods/log`, `pods/eviction`,
  `deployments/scale`, `*/status`. `pods: ["*"]` does not include them; `"*/*"`-style wildcards do.
- Testing them: `kubectl auth can-i create pods --subresource=exec`. Written as `pods/exec`, can-i reads
  `<resource>/<name>` and asks about a *pod named* `exec` - and `get pods/log` then says "yes" for anyone
  who may get pods.
- exec = shell in a container = access to its Secrets and ServiceAccount token: grant deliberately, audit it
  (T16's audit policy).
