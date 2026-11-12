## Hint 1
No pods → look at the ReplicaSet: `kubectl -n secure-apps describe rs -l app=reporter`. Or dry-run the pod:
`kubectl apply -f workspace/A04/reporter.yaml --dry-run=server`.

## Hint 2
The PodSecurity admission plugin lists every violation: privileged, allowPrivilegeEscalation,
capabilities, runAsNonRoot, seccompProfile.

## Hint 3
Container `securityContext: {privileged: false, allowPrivilegeEscalation: false, capabilities: {drop: [ALL]}}`,
pod `securityContext: {runAsNonRoot: true, seccompProfile: {type: RuntimeDefault}}` (labapp runs as uid 10001).
