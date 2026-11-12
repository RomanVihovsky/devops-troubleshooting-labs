## Hint 1
`kubectl -n api get hpa`, `kubectl -n api describe hpa api` (events). Who else writes `spec.replicas`?

## Hint 2
The HPA owns `replicas` of its target and never goes below `minReplicas` - your scale is overwritten at its next
sync (15 s).

## Hint 3
`kubectl -n api patch hpa api -p '{"spec":{"minReplicas":2}}'`. With no load it scales down to 2 (after the
scale-down stabilization window, 5 min by default - or scale to 2 yourself now).
