## Hint 1
`kubectl auth can-i get secret/db-creds -n payroll --as=system:serviceaccount:payroll:syncer`. Then
`kubectl -n payroll get role,rolebinding -o yaml`. Why does the app pod not need any of this?

## Hint 2
`resourceNames` must match the object name exactly - look at every character. And `resourceNames` can't
restrict `list`/`watch` (names aren't known up front) - don't add those verbs.

## Hint 3
Fix the Role (`resourceNames: [db-creds]`), apply. A finished Job never runs again: `kubectl -n payroll
delete job secret-sync` and apply `payroll.yaml` again.
