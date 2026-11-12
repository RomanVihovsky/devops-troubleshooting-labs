# W03: admin's pods carry app=web too - Service web (selector app=web) balances over both apps
kns market
ka -f market.yaml
wait_rollout market deploy/web; wait_rollout market deploy/admin
