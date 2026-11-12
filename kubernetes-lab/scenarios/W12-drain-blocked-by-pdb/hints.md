## Hint 1
`kubectl -n ha get pdb ha-api` (ALLOWED DISRUPTIONS) and `kubectl -n ha get pdb ha-api -o yaml`.

## Hint 2
`minAvailable: 3` with 3 replicas allows 0 voluntary disruptions - every eviction is refused, so a drain can never
finish. That's a budget that blocks maintenance, not one that protects availability.

## Hint 3
`kubectl -n ha patch pdb ha-api --type merge -p '{"spec":{"minAvailable":2}}'`, then
`kubectl drain k8s-w1 --ignore-daemonsets --delete-emptydir-data`, then `kubectl uncordon k8s-w1`.
