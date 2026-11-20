# wallet's new pods crash-loop since the egress guard went live
**INC-2711** · P1 · Reporter: team wallet

Security rolled out *egress-guard* today: a mutating webhook (`security-system`, `workspace/A10/egress-guard.yaml`)
that adds the corporate proxy to every pod in namespaces labelled `egress=guarded`, so that traffic to the
internet goes through the proxy. Since then every **new** `wallet` pod restarts over and over (liveness fails,
*upstream ... proxy ...* in the log); the old pods still serve, and our rollout is stuck. Our manifests haven't
changed. The proxy settings must stay in our pods - security audits that - but wallet's calls to
`ledger-api` inside the cluster have no business going through a proxy.

**Test**: `wallet` finishes its rollout with 2 Ready pods that stay up without restarts; the pods still carry the
injected `HTTPS_PROXY`; egress-guard still mutates pods in namespace `wallet`.
