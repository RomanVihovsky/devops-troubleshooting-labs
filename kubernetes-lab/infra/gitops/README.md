# lab/gitops

The lab's GitOps repository (Gitea on k8s-gw: http://git.lab:3000/lab/gitops). Argo CD syncs it; the tag
`baseline` is the state every lab reset goes back to.

| Path | What |
|---|---|
| `bootstrap/root.yaml` | the root Application `lab-apps` (applied once by `./lab gitops seed`) |
| `apps/` | what the root app manages: AppProject `lab`, Applications `demo` and `shop` |
| `charts/labapp`, `charts/shop` | the Helm charts Argo CD renders |
| `envs/<app>/values.yaml` | per-app values - **this is where changes go** |
| `.sops.yaml`, `secrets/` | SOPS + age (lab recipient) for encrypted files |

Secrets never sit here in plain text: `demo` uses a SealedSecret (ciphertext in `envs/demo/values.yaml`,
sealed for namespace `demo`, name `demo-auth`), `shop` an ExternalSecret that reads OpenBao `secret/shop`.
