# D01 - two silent failures in one values change

**Root cause**: the release commit set `image.tag: "1.4.0"` - the registry only has `1.4` - and
`app.greting: Bonjour`. The new ReplicaSet's pods sit in ImagePullBackOff; the rolling update keeps the old
pods, so demo still serves (Hello). And `greting` is not a key the chart reads: Helm renders without it and
says nothing.

**Diagnosis**
```
argocd app get demo                                   # Synced, health Progressing
kubectl -n demo describe pod <new pod>                # Failed to pull ... 1.4.0: not found
curl -s http://192.168.56.20:5000/v2/lab/labapp/tags/list
git -C workspace/gitops log -p -1                     # the commit
helm template demo charts/labapp -f envs/demo/values.yaml | grep -A1 GREETING   # empty
```

**Fix** (in Git): `image.tag: "1.4"`, `app.greeting: Bonjour`; push; Argo CD syncs.

**Interview notes**
- *Synced* only means "the cluster matches Git"; *Healthy* is the rollout result. A rolling update hides a
  bad image until `progressDeadlineSeconds` (Degraded) - the old pods keep serving.
- Helm values have no typo protection unless the chart ships a `values.schema.json`. Catch it in CI:
  `helm lint --strict`, `helm template | kubeconform`, a schema, or diffing the rendered manifests
  (`argocd app diff`, `helm diff`) - the diff would have shown *no* GREETING change.
- Tags are not immutable promises: pin what you tested, check the registry in CI.
