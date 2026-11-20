# Our deploy pipeline is blocked by a field-manager conflict
**INC-2719** · P3 · Reporter: team inventory

Our pipeline deploys `inventory-api` with server-side apply:

    kubectl apply --server-side --field-manager=pipeline-inventory -f inventory-api.yaml

Today's change (`workspace/O10/inventory-api.yaml`: `LOG_LEVEL` to `debug` for a bug hunt) fails with
*Apply failed with 1 conflict: conflict with "ops-hotfix" ... env[name="LOG_LEVEL"].value*. Last week's incident
was mitigated by on-call with a quick server-side patch - that is over. The pipeline must own its manifest again,
so that its next runs go through **without** forcing anything.

**Test**: `inventory-api` runs with `LOG_LEVEL=debug`; field manager `pipeline-inventory` owns that value and
`ops-hotfix` owns no env value any more; the pipeline's apply of the file (without `--force-conflicts`)
now succeeds.
