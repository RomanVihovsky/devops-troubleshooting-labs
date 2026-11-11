# k8s-w1 NotReady after "maintenance"
**INC-2412** · P2 · Reporter: on-call

`k8s-w1` went NotReady half an hour ago. Its kubelet keeps logging *x509: certificate has expired or is not
yet valid*. Nobody renewed or replaced any certificate. Someone was testing a licence tool on `k8s-w1` (it
"needed a fixed date"). Bring the node back, and make sure its time stays right: it must follow the lab's time
source on `k8s-gw` (192.168.56.20).

**Test**: chrony enabled and running on `k8s-w1`, synchronised to 192.168.56.20 with an offset under 1 s;
`k8s-w1` Ready; no certificate was replaced (the kubelet's client certificate is the original one).
