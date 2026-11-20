# R09 - scale-down stabilization 0 makes the HPA chase every burst

**Root cause**: the HPA has `behavior.scaleDown.stabilizationWindowSeconds: 0` and a policy that may remove 100 %
of the extra pods every 15 s. Every quiet gap of the bursty traffic produces a low recommendation, and the HPA
acts on it immediately - then the next burst hits 2 cold pods (10 s warm-up) and it scales up again.

**Diagnosis**
```
kubectl -n catalog describe hpa catalog-api       # events: New size: 6 ... above target / New size: 2 ... below target
kubectl -n catalog get hpa catalog-api -w
kubectl -n catalog get hpa catalog-api -o yaml    # behavior.scaleDown.stabilizationWindowSeconds: 0
```

**Fix**: give scale-down a memory - the default 300 s window (or delete the `scaleDown` block):
```yaml
behavior:
  scaleUp:   {stabilizationWindowSeconds: 0}
  scaleDown: {stabilizationWindowSeconds: 300}
```
With a window the HPA scales down to the **highest** recommendation of the last 300 s, so the 35 s gaps never
count; it shrinks only after 5 quiet minutes.

**Interview notes**
- Defaults: scaleUp window 0 s (react fast), scaleDown window 300 s (react slowly) - asymmetric on purpose.
- `policies` limit the step size (Pods/Percent per `periodSeconds`); `selectPolicy: Max|Min|Disabled`.
- The HPA also ignores changes within a 10 % tolerance, and treats not-yet-ready pods conservatively
  (CPU initialization period), which is why the warm-up matters.
- The HPA keeps recommendations only for its longest window: right after raising it, the history is short -
  one more scale-down can still happen in the first minute.
- Flapping costs more than it saves: cold caches, connection churn, image pulls, scheduler load.
