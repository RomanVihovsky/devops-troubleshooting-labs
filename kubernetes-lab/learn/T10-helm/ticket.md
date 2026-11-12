# T10 · Helm: chart anatomy, values precedence, upgrade, failed release, rollback
**Learn** · what Helm renders, what it stores, and how a bad release is undone · ~40 min

`workspace/T10/labapp/` is the lab's own chart (the one Argo CD deploys for `demo` and `shop`), and
`values-t10.yaml` your values file. Release name **`web`**, namespace **`t10`**.

1. **Anatomy**: `Chart.yaml`, `values.yaml`, `templates/`. `helm lint labapp` and
   `helm template web labapp -f values-t10.yaml` - what would be created?
2. **Install** revision 1 with `values-t10.yaml` (labapp **1.3**, 2 replicas).
3. **Upgrade** to labapp **1.4** with `--set image.tag=1.4` on top of the same values file. Which value
   wins, and why? (`helm get values web`, `helm get values web --all`)
4. **A bad release**: upgrade to **1.5** (it crashes on start) with `--wait --timeout 90s`. Look at
   `helm history web` and `helm status web`.
5. **Roll back** to revision 1 (`helm rollback`), and confirm the pods run 1.3 again.
6. Helm keeps every revision as a Secret in the release namespace: how many are there now? Decode one
   (`base64 -d | base64 -d | gunzip`) - which **chart version** does it record? (`answers.yaml`)

**Test**: release `web` is deployed by "Rollback to 1", its history has a failed revision, the Deployment
runs labapp 1.3 with 2 ready replicas, and the 2 answers match.
