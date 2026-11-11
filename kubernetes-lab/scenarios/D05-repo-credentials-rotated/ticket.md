# Argo CD lost the Git repo after the password rotation
**INC-2311** · P2 · Reporter: platform team

Security rotated the passwords of the Gitea service accounts this morning, `argocd` included. Since then
Argo CD shows every app as *Unknown* with "repository not accessible", and nothing deploys any more. The new
password is in OpenBao at `secret/ci/gitea-argocd` (key `password`). Get Argo CD reading `lab/gitops` again,
with its own read-only account and not a borrowed admin token.

**Test**: after a hard refresh, `lab-apps`, `demo` and `shop` are Synced + Healthy with no ComparisonError;
Argo CD's credentials for the repo are user `argocd` with the new password; the old password no longer works
in Gitea.
