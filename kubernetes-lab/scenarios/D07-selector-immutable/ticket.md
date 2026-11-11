# Nothing deploys since the labapp chart refactor
**INC-2325** · P2 · Reporter: release manager

This morning a chart change was merged: "select pods by version too, so we can route per version later".
Since then every sync of `demo` and `shop` fails with *spec.selector: Invalid value ... field is immutable*.
The sites still answer (the old pods run), but no release can go out, and today's release is due. Make the
chart deployable again, the GitOps way. Forcing it through (`Replace=true`, deleting the Deployments by hand)
is not an option the team accepts for a chart that every app uses.

**Test**: demo and shop are Synced + Healthy and their last sync Succeeded; demo.lab (with its token) and
shop.lab answer; at `main` the chart's Deployment selector is only `app.kubernetes.io/name` + `instance`
(stable across versions) and pods still carry `app.kubernetes.io/version`; no `Replace=true` sync option
anywhere.
