# Deploy fails: 'The container name "/tfl-api" is already in use'
**INFRA-222** · P2 · Reporter: API team

We deploy by changing `color` in `stacks/api/terraform.tfvars` - the container is replaced and, thanks
to `create_before_destroy`, the new one starts before the old one goes away (zero downtime; clients
use the network alias `api`). Today's deploy to `green` fails with
`Conflict. The container name "/tfl-api" is already in use`. Blue is still running.

Deploy green. Keep zero downtime (create-before-destroy) and keep the `api` alias.

**Test**: exactly one api container runs, with `APP_COLOR=green`, reachable as `api` on `tfl-api-net`;
another color change would still be create-before-destroy; a CI plan shows no changes.
