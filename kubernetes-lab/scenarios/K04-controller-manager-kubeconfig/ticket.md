# new Deployment "web" has no pods, scaling does nothing
**INC-2298** · P2 · Reporter: ops team

`kubectl -n ops create deployment web ...` succeeded, but `kubectl -n ops get rs,pods` is empty, and
scaling any Deployment changes nothing. The control plane was "tidied up" last night (config file
renames). `kubectl` itself works fine.

**Test**: kube-controller-manager runs and is Ready with a kubeconfig that exists; `ops/web` has 2 ready
replicas; only the 4 control-plane manifests in `/etc/kubernetes/manifests`.
