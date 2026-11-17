## Hint 1
`kubectl -n catalog describe hpa catalog-api` - read the events (*New size*) and the `behavior` section. How long
does the HPA wait before it believes a lower recommendation?

## Hint 2
`behavior.scaleDown.stabilizationWindowSeconds: 0` makes the HPA act on the newest recommendation at once. The
default for scale-down is **300 s**: the HPA uses the highest recommendation of the last 5 minutes, which rides
out quiet gaps between bursts.

## Hint 3
Set `scaleDown.stabilizationWindowSeconds` to 300 (or delete the `scaleDown` block for the default) and apply.
Leave `scaleUp` fast.
