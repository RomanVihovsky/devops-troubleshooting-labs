# Where is the metrics app?
**INC-2352** · P3 · Reporter: team observability

We merged our Application yesterday: `apps/team/metrics.yaml` in `lab/gitops`, project `lab`, namespace
`metrics`, the destination already allowed. `argocd app list` doesn't show it, there is no `metrics`
namespace, and the root app `lab-apps` says Synced + Healthy as if nothing happened. Teams will keep their
apps under `apps/<team>/` from now on.

**Test**: the Application `metrics` exists in `argocd` and is Synced + Healthy, its pods run in `metrics`;
`lab-apps` is Synced + Healthy; `apps/team/metrics.yaml` is still where the team put it (they'll add more
apps there).
