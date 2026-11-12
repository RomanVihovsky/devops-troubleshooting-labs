# k8s-w1 is busy - who is it?
**INC-2538** · P3 · Reporter: capacity team

`k8s-w1`'s CPU has been high since this morning and the tenants' apps there got slow. Five tenant services run on
it (namespace `tenants`). Find the pod that burns the CPU and write it into `workspace/Q03/answers.yaml`. Don't
kill anything yet - the owner must be asked first.

**Test**: the answer names the pod (or its Deployment) that uses most CPU on `k8s-w1`; all tenant pods still run.
