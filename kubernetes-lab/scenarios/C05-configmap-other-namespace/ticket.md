# checkout pods never start: "configmap app-config not found"
**INC-2442** · P2 · Reporter: team checkout

`checkout` (namespace `checkout`) stays in *CreateContainerConfigError: configmap "app-config" not found*.
But it exists - `kubectl get configmap app-config` shows it, created this morning from our runbook
(`workspace/C05/app-config.yaml`).

**Test**: `checkout` has 2 Ready pods that greet with `Hej` (the value from `app-config`); the pods still
read it from a ConfigMap named `app-config`.
