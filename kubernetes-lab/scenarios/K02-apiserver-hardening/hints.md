## Hint 1
No API means no kubectl: on k8s-cp1 use `crictl ps -a | grep apiserver`, `crictl logs <id>` and
`journalctl -u kubelet --since -10min | grep -i apiserver`. Keep a copy of the manifest **outside** the
manifests directory before editing.

## Hint 2
The container log names the first fatal error; fix it, wait, look again. One error never reaches the
container: if the kubelet refuses the manifest itself, there is no new container at all - the kubelet log
says why.

## Hint 3
`PodSecurityPolicy` was removed in 1.25 (unknown admission plugin); the cert is
`/etc/kubernetes/pki/apiserver.crt`; label values can't contain spaces. `--profiling=false` is fine - keep it.
