# A01 - RoleBinding in the wrong namespace

**Root cause**: Role and RoleBinding live in `default`. A RoleBinding grants permissions in *its own*
namespace: the scraper may list pods in `default`, not in `monitor`.

**Fix**: Role + RoleBinding in `monitor`; delete the ones in `default` (they grant access nobody wanted).

**Interview notes**
- Role/RoleBinding = namespaced; ClusterRole/ClusterRoleBinding = cluster-wide. A ClusterRole bound with a
  RoleBinding = that ClusterRole's rules, in that one namespace (the reuse pattern).
- `kubectl auth can-i --list --as=system:serviceaccount:ns:sa -n ns` shows everything a subject can do.
- "Fixing" with a ClusterRoleBinding works and fails least privilege.
