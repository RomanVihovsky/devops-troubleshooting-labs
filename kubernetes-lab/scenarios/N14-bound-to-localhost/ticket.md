# ledger-ui: fine via port-forward, dead via the Service
**INC-2614** · P2 · Reporter: ledger team

`kubectl port-forward deploy/ledger-ui 8080` works perfectly, pods are Ready, the Service has endpoints -
but `http://ledger-ui.ledger-ui` gives *connection refused*. Security asked us last week to "not listen on
all interfaces". Manifest: `workspace/N14/ledger-ui.yaml`.

**Test**: `http://ledger-ui.ledger-ui/` answers 200 inside the cluster; the readiness probe is still there.
