## Hint 1
`kubectl -n analytics logs deploy/etl` and `kubectl get nodes -o wide` (`ARCH` via
`kubectl get node -o jsonpath='{.items[*].status.nodeInfo.architecture}'`). "exec format error" = the kernel
can't run that binary.

## Hint 2
Which platform is the image built for? On `k8s-gw` (`./lab node gw`) `crane` reads image metadata:
`crane config --insecure registry.lab:5000/lab/labapp:1.6 | jq .architecture` (compare with `:1.4`).

## Hint 3
1.6 is an arm64 image under an ordinary tag (no multi-arch index), so the runtime didn't refuse it. Roll back to
`1.4` (`kubectl -n analytics set image deploy/etl etl=registry.lab:5000/lab/labapp:1.4`) until the build server
publishes a proper amd64 (or multi-arch) 1.6.
