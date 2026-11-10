## Hint 1
`kubectl -n analytics describe pod <pod>`: who restarts it, and after how many seconds? `WARMUP_SECONDS` in
the manifest says how long the dataset load takes.

## Hint 2
initialDelay 10 s + 3 × 5 s ≈ 25 s - the app needs 45 s before its port even opens. Raising the liveness
delay would also slow down hang detection later.

## Hint 3
Add a `startupProbe` (e.g. `httpGet /health`, `periodSeconds: 5`, `failureThreshold: 24` → up to 120 s):
liveness and readiness only start once it succeeded.
