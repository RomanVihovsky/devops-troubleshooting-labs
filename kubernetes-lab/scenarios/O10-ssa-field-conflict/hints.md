## Hint 1
`kubectl -n inventory get deploy inventory-api -o yaml --show-managed-fields` - who owns which field? Find
`f:env` under each manager.

## Hint 2
With server-side apply every field has owners. Changing a field another **applier** owns is a conflict, by design.
You can take it over (`--force-conflicts`: the other manager loses that field), or the other manager can give it
up by applying a configuration that no longer contains it.

## Hint 3
The hotfix is over, so take ownership once: `kubectl apply --server-side --field-manager=pipeline-inventory
--force-conflicts -f inventory-api.yaml`. Then run the pipeline's normal command again - no conflict.
