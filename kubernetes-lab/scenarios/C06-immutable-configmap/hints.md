## Hint 1
An immutable ConfigMap's `data` can never change - not by apply, not by edit. What *can* you change?

## Hint 2
Treat config like a release: a **new** ConfigMap (a new name, e.g. `pricing-config-v2`), immutable as well, and
point the Deployment at it. That change to the pod template rolls the pods.

## Hint 3
In `pricing.yaml`: add `pricing-config-v2` (immutable, `CURRENCY: USD`) and change `envFrom` to it; `kubectl apply`.
The old ConfigMap can stay for a rollback (or be deleted later).
