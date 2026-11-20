# New team payments can't deploy anything
**INC-2921** · P2 · Reporter: team payments (tina)

The platform team created namespace `payments-team` for us with the company baseline: a ResourceQuota, Pod Security
`restricted`, a RoleBinding for our group `payments-devs`, and a `default-deny` NetworkPolicy. We deploy with tina's
kubeconfig (`.state/scenario.b03-tina.kubeconfig`, `KUBECONFIG=... kubectl ...`) and our manifests
(`workspace/B03/payments.yaml`): nothing works - first *forbidden*, and after an admin applied it for us, no pods. The
baseline (quota, `restricted`, `default-deny`) stays; we only get rights in our own namespace.

**Test**: tina (group `payments-devs`) can create Deployments in `payments-team` but not in `default`; `payments-api` (2)
and `ledger` (1) are Ready, payments-api reaches ledger (its upstream check passes); the quota, the `restricted`
label and `default-deny` are unchanged.
