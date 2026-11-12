# SEC finding: every authenticated identity can read all Secrets
**SEC-124** · P1 · Reporter: security audit

The audit found that **any** authenticated user or ServiceAccount can list and read Secrets in every namespace.
It was introduced for the backup tool (ServiceAccount `backup/backup-agent`), which really does need to read all
Secrets. Fix it so that only the backup agent can.

**Test**: `backup/backup-agent` can still list Secrets in all namespaces; a normal user (`bob`) and an ordinary
ServiceAccount (`default/default`) can't read Secrets anywhere (no cluster-wide grant); nothing grants cluster-wide
Secret access to the group `system:authenticated` any more.
