# BLACK FRIDAY: storefront returns errors, 2 hours to the campaign
**INC-2900** · P1 · Reporter: e-commerce

The Black Friday storefront (namespace `bf`, `workspace/B01/`) went live this morning and answers *502* on every page.
It is `web` -> `catalog` (an internal Service). Security's zero-trust policies (`default-deny` and the allow rules)
were part of the release and stay. The campaign starts in 2 hours: catalog must **autoscale** under load, and the
platform team will drain a worker for maintenance during the campaign - the drain must not hang.

**Test**: `web` answers 200 from outside the namespace, also under 20 s of load; catalog's HPA has CPU metrics and can
scale; catalog's PodDisruptionBudget allows a disruption while keeping at least 2 pods; `default-deny` is unchanged.
