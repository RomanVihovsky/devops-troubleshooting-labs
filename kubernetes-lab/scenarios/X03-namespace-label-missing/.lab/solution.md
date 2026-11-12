# X03 - namespaceSelector matches labels, not names

**Root cause**: the policy allows `namespaceSelector: {matchLabels: {team: monitoring}}`. The namespace is *named*
`monitoring` but has no label `team=monitoring`, so the selector matched nothing.

**Diagnosis**
```
kubectl -n appx describe networkpolicy allow-monitoring
kubectl get ns monitoring --show-labels      # only kubernetes.io/metadata.name=monitoring
```

**Fix**: `kubectl label namespace monitoring team=monitoring`. Or, if the standard allowed it, select by the
automatic label `kubernetes.io/metadata.name: monitoring` (set by the API server on every namespace, immutable).

**Interview notes**
- Who may label namespaces? Whoever can `patch namespaces` can join "the monitoring team" in every policy
  that trusts the label. Use the immutable `kubernetes.io/metadata.name`, or restrict namespace labelling
  (policy engines).
- `namespaceSelector` + `podSelector` in **one** `from` item = AND; as **two** items = OR (X05).
