# Upgrading tf-module-pgbox to v2.0.0 destroys the database volume
**INFRA-262** · P1 · Reporter: inventory team (and 13 other consumers of the module)

`tf-module-pgbox` v2.0.0 ("consistent naming") was released yesterday. Our bump PR for
`stacks/inventory-db` plans to **destroy** `tfl-inventory-pgdata` - the Postgres data volume - and the
database container, then create them again. 13 other teams use the module and will hit the same thing.

Fix it **in the module** for everyone: publish a patch release that upgrades cleanly, and move
inventory onto it. The volume and the container must survive.

**Test**: inventory uses a release >= v2.0.1 of the module; that release upgrades v1 users without
replacing anything (the module itself handles it); the volume and the container are the originals; a CI
plan shows no changes.
