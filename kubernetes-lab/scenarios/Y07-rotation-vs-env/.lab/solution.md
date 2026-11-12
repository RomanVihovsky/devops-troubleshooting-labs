# Y07 - a rotated secret and an environment variable

**Root cause**: ESO did its job: OpenBao's new token reached Secret `api-token` within seconds. `upstream`
mounts the Secret as a volume. The kubelet updates the files in place, and labapp re-reads `AUTH_TOKEN_FILE`
on every request, so it switched to the new token. `notifier` gets the token through `env.valueFrom.
secretKeyRef`. Environment variables are resolved **once**, when the container starts, so it kept sending
the old token until a restart.

**Diagnosis**
```
kubectl -n notify get secret api-token -o jsonpath='{.data.token}' | base64 -d; echo
kubectl -n notify exec deploy/notifier -- labapp get http://localhost:8080/env | grep UPSTREAM_TOKEN   # masked, but set at start
kubectl -n notify get deploy notifier -o jsonpath='{.spec.template.spec.containers[0].env}'
kubectl -n notify get externalsecret api-token -o jsonpath='{.status.refreshTime}'
```

**Fix**: read the token from a file the kubelet keeps current:
```yaml
env:
  - {name: UPSTREAM_TOKEN_FILE, value: /etc/notify/token}
volumeMounts:
  - {name: token, mountPath: /etc/notify, readOnly: true}     # no subPath: subPath mounts never update
volumes:
  - {name: token, secret: {secretName: api-token}}
```
Alternatives: keep the env var but **restart on change**: Stakater Reloader
(`reloader.stakater.com/auto: "true"`), or a checksum annotation that the deploy tooling bumps. A restart
per rotation is acceptable when the app can't re-read files.

**Interview notes**
- Secret volumes update after the kubelet's sync period plus its cache TTL (typically under a minute or two).
  `subPath` mounts and env vars never update.
- Rotation needs an overlap window: the provider accepts old and new for a while, or consumers would fail
  between the provider's switch and theirs. Here upstream switched first, which caused the 401s.
- ESO `refreshInterval` bounds how stale the Secret is. `force-sync` annotations trigger a refresh by hand.
- Test rotations like here: rotate in a drill and watch every consumer. A process that "works with a restart"
  will fail on the night nobody restarts it.
