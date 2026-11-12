# Can't switch pricing to USD
**INC-2445** · P3 · Reporter: team pricing

We need `CURRENCY=USD` for the US launch today. Changing it in `workspace/C06/pricing.yaml` and applying gives
*ConfigMap "pricing-config" is invalid: data: Forbidden: field is immutable when `immutable` is set*. We made
our ConfigMaps immutable on purpose (fewer watches on the API server) and want to keep it that way.

**Test**: every `pricing` pod runs with `CURRENCY=USD`; the ConfigMap the Deployment uses is immutable and holds
`USD`; `pricing` has 2 Ready pods.
