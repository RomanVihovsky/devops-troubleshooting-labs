# W04 - OrderedReady waits for a Ready member

**Root cause**: the new readiness probe asks `/readyz`; labapp answers `/ready` (404 → not Ready). With
`podManagementPolicy: OrderedReady` the StatefulSet controller creates `quorum-1` only after `quorum-0` is
Running **and Ready**, so the set stayed at one unready member.

**Diagnosis**
```
kubectl -n quorum get pods                       # quorum-0 0/1 Running, nothing else
kubectl -n quorum describe pod quorum-0 | grep -A2 Readiness   # HTTP probe failed with statuscode: 404
kubectl -n quorum get sts quorum -o jsonpath='{.spec.podManagementPolicy}'; echo
```

**Fix**: the right path, apply, and delete `quorum-0`. A pod made from the broken template that never became
Ready is not replaced by the rolling update ("forced rollback" in the StatefulSet docs).

**Interview notes**
- `OrderedReady` (default): create 0..N-1 in order, each after the previous is Ready; delete in reverse.
  `Parallel`: all at once. The policy is immutable on an existing StatefulSet.
- StatefulSet rolling updates go from the highest ordinal down and also wait for Ready. A bad template can
  stop them halfway, and after a fix the broken pods must be deleted by hand.
- Readiness ≠ liveness: a failing readiness probe never restarts anything. It just blocks traffic and, here,
  the next member.
