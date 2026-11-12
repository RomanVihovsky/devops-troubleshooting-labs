## Hint 1
`kubectl -n shopx describe networkpolicy backend-allow` vs `kubectl -n shopx get pods --show-labels`.

## Hint 2
`from.podSelector` must match the **client** pods' labels exactly. Read the label value letter by letter.

## Hint 3
`matchLabels: {app: frontend}`, apply.
