# Security: the payments API key may have leaked
**INC-2801** · P1 · Reporter: security

The partner says somebody used our live API key from an unknown network within the last hour. The key lives in Secret
`api-key` in namespace `payments`. API server auditing is on (`/etc/kubernetes/audit/` on `k8s-cp1`). Find out
**who** read that Secret through the API in the last hour - people and workloads - and fill in
`workspace/A13/answers.yaml`. Don't weaken the audit policy (and don't make it log secret values).

**Test**: the answers name the ServiceAccount that read `payments/api-key`, the pod it ran in, and the human user
who read it; the audit policy still logs Secrets at the `Metadata` level and auditing is still on.
