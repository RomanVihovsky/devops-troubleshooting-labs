## Hint 1
`kubectl kustomize workspace/O08/overlays/prod | grep -E 'replicas|LOG_LEVEL'` and compare with the overlay's
patches. Which object does each patch say it targets?

## Hint 2
A patch with a `target:` selector applies to every matching resource - and to **none** if nothing matches,
silently. The base's Deployment is called `web`.

## Hint 3
`target: {kind: Deployment, name: web}` in `overlays/prod/kustomization.yaml`, then `kubectl apply -k
workspace/O08/overlays/prod`.
