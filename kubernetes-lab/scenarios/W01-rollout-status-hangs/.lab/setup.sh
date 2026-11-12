# W01: 1.5 exits at start; maxUnavailable 0 keeps the old pods; progressDeadlineSeconds 3600 hides it
kns storefront
ka -f storefront.yaml
wait_rollout storefront deploy/storefront
kx -n storefront set image deploy/storefront storefront=registry.lab:5000/lab/labapp:1.5 >/dev/null
crashing() { crashlooping storefront app=storefront; }
retry 150 crashing || die "1.5 did not crash"
