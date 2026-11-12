## Hint 1
`kubectl api-resources | grep -iE 'poddisruption|ingress'` and `kubectl explain ingress.spec.rules.http.paths.backend
--api-version=networking.k8s.io/v1`.

## Hint 2
`policy/v1beta1` PDBs and `extensions/v1beta1`/`networking.k8s.io/v1beta1` Ingresses were removed (1.25 and 1.22).
The v1 Ingress also changed shape: `backend.service.name/port.number` and a required `pathType`.

## Hint 3
PDB: `apiVersion: policy/v1` (same spec). Ingress: `apiVersion: networking.k8s.io/v1`, `pathType: Prefix`,
`backend: {service: {name: web, port: {number: 8080}}}`. (`kubectl convert` from the kubectl-convert plugin does it
too.)
