# K08 - a kubeconfig with three small mistakes

**Root cause**: three edits, one per kubeconfig layer:
1. `clusters[].cluster.server` → port **6444**: *connection refused* (nothing listens there).
2. `contexts[].context.user: dana@lab`, but the `users:` entry is `dana`: kubectl finds no credentials and
   reports an invalid configuration (in some versions it sends the request anonymously: *system:anonymous*).
3. `contexts[].context.namespace: shp` (typo): no error at all, just "No resources found in shp namespace."

**Diagnosis**
```
export KUBECONFIG=$PWD/workspace/K08/kubeconfig
kubectl config get-contexts           # CURRENT, CLUSTER, AUTHINFO, NAMESPACE in one line
kubectl config view --minify          # only what the current context uses
kubectl auth whoami                   # who the API server thinks you are
kubectl get pods -v=6                 # the URL and the response code
```

**Fix**
```
kubectl config set-cluster lab --server=https://192.168.56.20:6443
kubectl config set-context --current --user=dana --namespace=shop
```

**Interview notes**
- A kubeconfig is three lists (`clusters`, `users`, `contexts`) and `current-context`. A context is just a
  triple of names (cluster, user, namespace); a dangling name is the classic merge accident.
- Merging: `KUBECONFIG=a:b kubectl config view --flatten > merged`. On a name conflict the **first** file
  wins.
- `kubectl auth whoami` (SelfSubjectReview) answers "who am I": user, groups, and the authenticator's
  extras.
- Never "fix" TLS with `insecure-skip-tls-verify`; the CA data is in the file
  (`certificate-authority-data`).
