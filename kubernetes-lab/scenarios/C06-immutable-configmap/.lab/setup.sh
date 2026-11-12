# C06: the config is an immutable ConfigMap - an in-place change is rejected
kns pricing
ka -f pricing.yaml
wait_rollout pricing deploy/pricing
sed -i 's/CURRENCY: EUR/CURRENCY: USD/' pricing.yaml
! kx apply -f pricing.yaml >/dev/null 2>&1 || die "the immutable ConfigMap accepted the change"
