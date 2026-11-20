## Hint 1
`kubectl get lease -n kube-node-lease k8s-w1 -w` - how often is `renewTime` updated? Then `./lab node w1`,
`journalctl -u kubelet --since -10min | grep -iE 'lease|timeout|deadline'`.

## Hint 2
The kubelet's requests to the API server (via `192.168.56.20:6443`) time out, but SSH is fine - so it's not the
whole link. Look at the queueing disciplines: `tc qdisc show` and `tc filter show dev <nic>` on each interface.

## Hint 3
A `netem loss` qdisc behind a filter for the API server's address eats most of those packets. Remove the shaping:
`tc qdisc del dev <nic> root`.
