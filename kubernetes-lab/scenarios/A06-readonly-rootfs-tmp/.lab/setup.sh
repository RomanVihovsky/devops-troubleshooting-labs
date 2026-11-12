kns invoices
ka -f invoices.yaml
retry 120 crashlooping invoices app=invoices || die "no crash"
