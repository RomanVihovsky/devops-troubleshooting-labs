## Hint 1
No container means the scheduler never placed the task. `docker service ps --no-trunc app_reports`.
## Hint 2
"insufficient resources on 3 nodes". What does each node offer, and what does
the service ask for? `docker node inspect -f '{{.Description.Resources}}' worker1`
and `docker service inspect --pretty app_reports`.
## Hint 3
**Reservations** are booked at scheduling time against the node's total
memory/CPU (even if the app would use far less). Check `deploy.resources` in the stack file.
