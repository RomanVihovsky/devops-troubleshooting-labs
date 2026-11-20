## Hint 1
Three faults, three places. `kubectl -n kube-system get pods -o wide` (which control-plane pods are missing or not
Ready?), `kubectl get nodes`, then the node: `./lab node cp1` / `./lab node w3`.

## Hint 2
A static pod that doesn't appear at all: the kubelet couldn't **parse** its manifest (`journalctl -u kubelet | grep -i
manifest` on cp1). A pod that crashes: `crictl logs` says which file it can't open. A NotReady node: its kubelet's
log names the address it can't reach.

## Hint 3
Scheduler: the new flag is indented with a TAB - YAML forbids tabs. Controller-manager: `--kubeconfig` names a file
that doesn't exist (`ls /etc/kubernetes/*.conf`). w3: `server:` in `/etc/kubernetes/kubelet.conf` uses port 6444 -
the API listens on 6443; restart the kubelet.
