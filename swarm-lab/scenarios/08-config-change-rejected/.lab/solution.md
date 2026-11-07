# Solution - swarm configs/secrets are immutable

**Root cause**: `docker stack deploy` tries to update the existing config object
`app_greeting` with new content. Configs (and secrets) are immutable; only labels
may change -> `only updates to Labels are allowed`.

**Fix**: version the object name so a *new* config is created and the service is
rolling-updated to it:
```yaml
configs:
  greeting:
    name: app_greeting_v2        # bump on every content change (or use a hash)
    file: ./greeting.txt
```
Imperative equivalent:
```
docker config create greeting_v2 greeting.txt
docker service update --config-rm app_greeting \
  --config-add source=greeting_v2,target=/etc/app/greeting.txt app_web
```

**Real-world notes**: CI pipelines usually template the name with a content hash
(`name: app_greeting_${GREETING_SHA}`). Old versions must be cleaned up later
(`docker config rm`) once no service references them.
