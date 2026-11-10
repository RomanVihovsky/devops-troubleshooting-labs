kns billing
ka -f billing.yaml
retry 120 crashlooping billing app=billing || die "billing did not crashloop"
