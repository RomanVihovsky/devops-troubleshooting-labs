## Hint 1
Who creates Applications from `apps/`? `kubectl -n argocd get application lab-apps -o yaml` - look at
`spec.source`. Is `lab-apps` itself in Git? (`git -C workspace/gitops ls-files | grep -i root`)

## Hint 2
A directory source reads only the top level of `path` unless `directory.recurse: true`. `lab-apps` was
applied by hand from `bootstrap/root.yaml` - nothing syncs the root app itself.

## Hint 3
Set `spec.source.directory.recurse: true` on `lab-apps` (`kubectl -n argocd patch application lab-apps --type
merge -p '{"spec":{"source":{"directory":{"recurse":true}}}}'`) and put the same into
`bootstrap/root.yaml` in Git so the next bootstrap keeps it. Then `argocd app get lab-apps --refresh`.
