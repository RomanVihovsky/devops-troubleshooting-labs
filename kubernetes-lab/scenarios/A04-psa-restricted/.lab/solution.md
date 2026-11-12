# A04 - Pod Security admission rejects every pod

**Root cause**: `secure-apps` has `pod-security.kubernetes.io/enforce=restricted`. The pod template sets
`privileged: true` and none of the fields `restricted` requires, so the PodSecurity admission plugin rejected every
pod the ReplicaSet tried to create. The rejections are events on the ReplicaSet, and there are no pods.

**Diagnosis**
```
kubectl -n secure-apps describe rs -l app=reporter | grep -A3 FailedCreate     # violates PodSecurity "restricted:latest": privileged, ...
kubectl get ns secure-apps --show-labels
kubectl apply -f workspace/A04/reporter.yaml --dry-run=server       # the warnings/rejection at once
```

**Fix**: a compliant spec: no privileged, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`,
`runAsNonRoot: true` (the image's user must be non-root), `seccompProfile: RuntimeDefault`.

**Interview notes**
- PSA modes per namespace: `enforce` (reject), `audit` (audit log annotation), `warn` (kubectl warning). Roll
  out with warn/audit first, then enforce.
- Levels: `privileged` (anything), `baseline` (no host namespaces/privileged/hostPath...), `restricted`
  (baseline + non-root, drop ALL, seccomp).
- PSA only checks pods: Deployments are accepted and fail later, the "0 pods" symptom. Policy engines
  (Kyverno, Gatekeeper, ValidatingAdmissionPolicy) can reject the Deployment itself.
