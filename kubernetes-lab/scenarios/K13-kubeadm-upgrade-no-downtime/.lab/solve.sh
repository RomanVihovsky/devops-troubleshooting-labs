kx -n storefront patch pdb storefront --type merge -p '{"spec":{"minAvailable":2}}' >/dev/null
cluster_upgrade "$(recall k13_target)"     # lib/upgrade.sh: drains respect the (now possible) PDB
retry 120 deploy_ready storefront storefront 3 || true
