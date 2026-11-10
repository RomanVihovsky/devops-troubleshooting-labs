# no logs from k8s-cp1
**INC-2509** · P3 · Reporter: observability team

Our `log-agent` DaemonSet (namespace `logging`, `workspace/S09/log-agent.yaml`) is supposed to run on
**every** node - the control plane's logs matter most. `kubectl -n logging get ds` shows 3 desired, the
cluster has 4 nodes.

**Test**: log-agent runs and is ready on all 4 nodes, including k8s-cp1; the control-plane taint stays.
