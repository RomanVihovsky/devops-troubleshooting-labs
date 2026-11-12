# O08: the prod overlay's patch targets "webapp" - no match, so kustomize silently renders the base
kns kust-prod
kx kustomize overlays/prod | ka -f -
wait_rollout kust-prod deploy/web
