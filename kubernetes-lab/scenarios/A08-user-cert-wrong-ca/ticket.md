# alice can't use her kubeconfig
**INC-2610** · P3 · Reporter: alice (new engineer)

My kubeconfig (`workspace/A08/kubeconfig`, key `alice.key`, cert `alice.crt`) was made by a colleague "with the
team CA". Every command says *error: You must be logged in to the server (Unauthorized)*. I should be able to read
pods in `dev` (a RoleBinding for user `alice` exists). Please issue me a proper certificate - through the cluster's
CSR API, with my existing key (it never leaves my laptop).

**Test**: with `workspace/A08/kubeconfig`, `kubectl auth whoami` says `alice` and `kubectl -n dev get pods` works;
alice's certificate is signed by the cluster CA and matches her original key `alice.key`; alice has no access beyond
what the RoleBinding gives (she can't list pods in `kube-system`).
