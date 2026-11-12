## Hint 1
`kubectl describe node k8s-w3 | grep -A8 Capacity` - extended resources appear there when something advertises
them (normally a device plugin through the kubelet).

## Hint 2
Extended resources can be advertised by patching the Node's **status** (capacity); the kubelet then reports the
same amount as allocatable. `kubectl patch` can write the status subresource (`--subresource=status`).

## Hint 3
`kubectl patch node k8s-w3 --subresource=status --type=json -p '[{"op":"add","path":"/status/capacity/example.com~1gpu","value":"2"}]'`
(`~1` encodes the `/` in the name). The scheduler places trainer within seconds.
