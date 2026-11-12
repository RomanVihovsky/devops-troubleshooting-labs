## Hint 1
Read the apply error word by word, then `kubectl explain pod.spec.containers.env.valueFrom.fieldRef.fieldPath`.

## Hint 2
Field paths are case-sensitive (`status.podIP`). Once it deploys, check `kubectl -n inventory exec deploy/inventory
-- printenv MEMORY_LIMIT_MB`: with no memory limit, `limits.memory` reports the node's allocatable memory.

## Hint 3
`fieldPath: status.podIP`, and `resources: {limits: {memory: 256Mi}}` on the container (keep the
`resourceFieldRef` with `divisor: 1Mi`). Apply.
