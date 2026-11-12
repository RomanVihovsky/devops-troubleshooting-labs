## Hint 1
`kubectl get nodes -o wide` has a CONTAINER-RUNTIME column (`containerd://X.Y.Z` - the answer is `X.Y.Z`).
`-L topology.kubernetes.io/zone` adds the zone as a column. `kubectl get svc -A | grep LoadBalancer` and
`kubectl get storageclass` (the default one is marked).

## Hint 2
On k8s-gw: `grep -A5 '^backend' /etc/haproxy/haproxy.cfg` - the `server` line. In `./lab list` the columns
are ID, level, reset level, title.

## Hint 3
```
kubectl -n t01 create deployment hello --image=registry.lab:5000/lab/labapp:1.4 --replicas=2 --port=8080
kubectl -n t01 expose deployment hello --port=80 --target-port=8080
kubectl -n t01 run probe --rm -it --restart=Never --image=docker.io/library/busybox:1.37 -- wget -qO- http://hello
```
