# C02: the config file is mounted with subPath - edits to the ConfigMap never reach the running pods
kns catalog
ka -f catalog.yaml
wait_rollout catalog deploy/catalog
sed -i 's/greeting = Hello/greeting = Bonjour/' catalog.yaml
ka -f catalog.yaml
