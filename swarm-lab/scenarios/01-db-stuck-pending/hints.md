## Hint 1
A task that never started has no logs. Ask the **scheduler** instead:
`docker service ps --no-trunc app_db` and read the CURRENT STATE / ERROR columns.
## Hint 2
"no suitable node (scheduling constraints not satisfied ...)". Compare what the
constraint asks for with what the nodes actually carry:
`docker node inspect -f '{{.Description.Hostname}} {{json .Spec.Labels}}' $(docker node ls -q)`
## Hint 3
The label exists, but look closely at its **key**. Either fix the label
(`docker node update --label-add ...`) or fix the constraint and redeploy.
