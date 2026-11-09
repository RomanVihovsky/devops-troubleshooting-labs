## Hint 1
A Service only forwards to its **endpoints**. What does `kubectl -n orders get endpointslices` show for
`backend`?

## Hint 2
Endpoints come from the Service's `selector` matching pod **labels**. Compare
`kubectl -n orders get svc backend -o jsonpath='{.spec.selector}'` with
`kubectl -n orders get pods --show-labels`.

## Hint 3
The pods are labelled `app: back-end`, the Service selects `app: backend`. The ticket says the pod labels
must stay - so fix the Service: `kubectl -n orders patch svc backend -p '{"spec":{"selector":{"app":"back-end"}}}'`
(or fix `workspace/N01/orders.yaml` and `kubectl apply -f` it).
