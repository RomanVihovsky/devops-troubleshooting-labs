# Worker deploy fails after the controller upgrade: "Type 'range' is unsupported for variable storage"
**OPS-262** · P2 · Reporter: app team

The runner image moved from ansible-core 2.16 to 2.22. The `workers` role worked for two years; now:
```
[ERROR]: Error rendering template: Type 'range' is unsupported for variable storage.
```
Keep the data model: the number of workers is `workers_count`, and a file entry without an owner must stay
"no owner set" (whoever runs the deploy).

**Test**: site.yml deploys and converges; `workers_count` workers get spool dirs (also with `-e '{"workers_count": 4}'`);
both config files exist.
