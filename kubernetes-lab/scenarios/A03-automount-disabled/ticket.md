# janitor can't talk to the API any more
**INC-2803** · P3 · Reporter: platform team

The `janitor` (namespace `janitor`, `workspace/A03/janitor.yaml`) lists pods through the API with its
ServiceAccount. Since the security team's "token hygiene" change last week it fails: no token file, and
anonymous requests are rejected. Its RBAC is fine. Security wants tokens only where they're needed - other
ServiceAccounts in the namespace must keep automount off.

**Test**: the janitor pod has its ServiceAccount token and can list pods in `janitor` through the API;
the `default` ServiceAccount of `janitor` keeps automount off.
