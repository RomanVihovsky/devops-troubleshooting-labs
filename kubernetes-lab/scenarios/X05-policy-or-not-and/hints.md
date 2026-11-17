## Hint 1
`kubectl -n db get networkpolicy allow-prometheus -o yaml` - count the entries under `ingress[0].from`.
`kubectl describe` prints them as separate sources.

## Hint 2
Each item of `from` is a separate source and they are **OR**ed. A `namespaceSelector` and a `podSelector` in the
**same** item are **AND**ed ("these pods in those namespaces"). One `-` too many changes the meaning.

## Hint 3
Merge the two items into one: `- namespaceSelector: {...}` followed by `podSelector: {...}` at the same
indentation, without a second dash. Apply.
