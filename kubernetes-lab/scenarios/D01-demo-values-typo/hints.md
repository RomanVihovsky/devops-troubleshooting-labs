## Hint 1
`kubectl -n demo get pods`, `kubectl -n demo describe pod <new pod>`: what does the kubelet say about the
image? `git -C workspace/gitops log -p -1` shows exactly what the release commit changed.

## Hint 2
Which labapp tags exist? `curl -s http://192.168.56.20:5000/v2/lab/labapp/tags/list`. And the greeting:
`helm show values` of the chart (`charts/labapp/values.yaml` in the repo) - is every key in the commit one
the chart knows? Helm ignores unknown keys without a word (there is no values.schema.json).

## Hint 3
In `envs/demo/values.yaml`: `image.tag: "1.4"` and `app.greeting: Bonjour` (not `greting`). Commit, push,
`argocd app get demo --refresh`. Check: `curl -H 'Host: demo.lab' -H "Authorization: Bearer $(cat
.state/demo-token)" http://192.168.56.200/`.
