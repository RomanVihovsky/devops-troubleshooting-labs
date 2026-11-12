sed -i 's/target: {kind: Deployment, name: webapp}/target: {kind: Deployment, name: web}/' overlays/prod/kustomization.yaml
kx apply -k overlays/prod >/dev/null
wait_rollout kust-prod deploy/web 120
