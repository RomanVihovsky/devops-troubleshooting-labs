# CI: "You need to install jmespath prior to running json_query filter" - but the EE declares it
**OPS-336** · P2 · Reporter: web team

Our new catalog task uses `community.general.json_query`. It works from the controller (`ansible-playbook site.yml`),
but the CI job - which runs inside the execution environment (`ci/README.md`) - fails. Platform says they
added jmespath to `ee/execution-environment.yml` last week (`git log`).

Released EE tags are immutable (other runners cache them).

**Test**: the image named in `ci/ee-image` is a new tag (not `acme/ee:1`), contains ansible-core 2.22.0 and
jmespath, and site.yml converges inside it; `acme/ee:1` itself is unchanged; web1 lists `shop,api`.
