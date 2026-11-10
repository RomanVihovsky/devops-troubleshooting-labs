sed -i 's|value: http://api/items|value: http://api.inventory-api/items|' storefront.yaml
kx apply -f storefront.yaml >/dev/null
wait_rollout storefront deploy/storefront
