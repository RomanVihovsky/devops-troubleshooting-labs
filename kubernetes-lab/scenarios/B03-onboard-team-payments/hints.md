## Hint 1
Go layer by layer and read every error: `KUBECONFIG=.state/scenario.b03-tina.kubeconfig kubectl -n payments-team
auth can-i create deployments`, then `kubectl -n payments-team describe rs` (FailedCreate events), then the pods.

## Hint 2
Four gates: RBAC (who is the RoleBinding's subject - exactly?), the ResourceQuota (pods must declare what it limits),
Pod Security `restricted` (securityContext fields), and NetworkPolicy (`default-deny` blocks DNS **and** pod-to-pod).

## Hint 3
Fix the RoleBinding's group to `payments-devs`; add requests/limits and a restricted-compliant securityContext
(runAsNonRoot, seccomp RuntimeDefault, no privilege escalation, drop ALL) to both Deployments; add policies for DNS
egress and payments-api -> ledger. Then apply as tina.
