# anna can't exec into her pods
**INC-2802** · P3 · Reporter: anna (team-blue)

I can list and read logs of the pods in `team-blue`, but `kubectl exec` says *pods "..." is forbidden:
User "anna" cannot create resource "pods/exec"*. Our Role is in `workspace/A02/rbac.yaml`. I should be able
to exec - but not delete pods or read Secrets.

**Test**: user `anna` can exec into pods in `team-blue`, still list pods and read logs, and can't delete
pods or read secrets there, nor do anything in other namespaces.
