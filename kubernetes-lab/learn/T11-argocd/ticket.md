# T11 · Argo CD: app-of-apps, AppProject, manual vs automated sync, self-heal
**Learn** · how an app gets from Git into the cluster, and who is allowed to put it where · ~40 min

Argo CD (`./lab ui`; `argocd login 192.168.56.201 --plaintext`) runs the root app **`lab-apps`**: it syncs
every manifest under `apps/` of `lab/gitops` - Applications (`demo`, `shop`) and the AppProject `lab`.
Your clone is `workspace/gitops`; a starter Application is in `workspace/T11/t11.yaml`.

1. Look around: `argocd app list`, `argocd app get lab-apps`, `apps/` and `apps/project-lab.yaml`.
2. Add the Application **`t11`** to Git: `apps/t11.yaml` (project `lab`, the labapp chart, namespace
   `t11`, **no automated sync yet**). Push, refresh `lab-apps`. What does `t11` say?
3. The project `lab` decides which destinations its apps may use: let `t11` in - **in Git**, not with
   kubectl (lab-apps would revert it).
4. **Sync** `t11` by hand (`argocd app sync t11`), until it is Synced + Healthy.
5. Turn on **automated sync with self-heal** for `t11` (in Git). Then `kubectl -n t11 scale deploy t11
   --replicas=5` and watch Argo CD put it back.

**Test**: `apps/t11.yaml` on main defines t11 (namespace t11, automated + selfHeal) and the AppProject in Git
permits `t11`; the Application `t11` was created by `lab-apps`, is Synced + Healthy, and a manual scale is
reverted within a minute.
