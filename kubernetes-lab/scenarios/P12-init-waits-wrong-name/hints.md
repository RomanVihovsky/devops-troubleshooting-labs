## Hint 1
`kubectl -n orders-db logs <pod> -c wait-for-db` - what is it waiting for?

## Hint 2
`kubectl -n orders-db get svc` - what is the database Service called now?

## Hint 3
Change the name the init container resolves to `postgresql`, apply.
