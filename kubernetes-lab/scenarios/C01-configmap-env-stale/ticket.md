# The promo greeting didn't change
**INC-2430** · P3 · Reporter: marketing

For the campaign we changed `GREETING` in the ConfigMap `promo/promo-config` from `Hello` to `Bonjour` an hour
ago (`kubectl get cm promo-config -o yaml` shows it). The `promo` pages still say "Hello from ...".
(`workspace/C01/promo.yaml` is what's deployed.)

**Test**: every `promo` pod answers "Bonjour from ..."; the value still comes from the ConfigMap
`promo-config` (no greeting hard-coded in the Deployment).
