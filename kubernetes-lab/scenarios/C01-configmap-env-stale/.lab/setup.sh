# C01: GREETING comes from a ConfigMap via envFrom; the ConfigMap is changed afterwards
kns promo
ka -f promo.yaml
wait_rollout promo deploy/promo
# the campaign change, made the way the team works: edit the file, apply it
sed -i 's/GREETING: Hello/GREETING: Bonjour/' promo.yaml
ka -f promo.yaml
