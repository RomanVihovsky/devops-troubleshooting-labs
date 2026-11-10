## Hint 1
`kubectl -n catalog describe pod <pod>` - the Events at the bottom say exactly what the kubelet tried to
pull and what the registry answered.

## Hint 2
Which tags exist? `curl -s http://192.168.56.20:5000/v2/lab/labapp/tags/list`.

## Hint 3
`1.4.0` doesn't exist, `1.4` does. Fix the tag in `catalog.yaml`, `kubectl apply -f catalog.yaml`.
