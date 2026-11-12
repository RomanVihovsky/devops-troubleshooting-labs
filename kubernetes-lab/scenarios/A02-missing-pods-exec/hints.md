## Hint 1
`kubectl auth can-i create pods --subresource=exec -n team-blue --as=anna` vs `get pods`.

## Hint 2
`exec`, `attach`, `port-forward`, `log` are **subresources** of pods with their own RBAC entries; exec is
the verb `create` on `pods/exec` (plus `get` for websockets).

## Hint 3
Add `{apiGroups: [""], resources: [pods/exec], verbs: [create, get]}` to the Role, apply.
