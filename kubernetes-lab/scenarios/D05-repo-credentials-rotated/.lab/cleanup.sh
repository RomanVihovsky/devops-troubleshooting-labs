# the argocd account's password back to the one in .state (the GitOps reset then restores repo-gitops)
gitea_argocd_user || warn "D05: Gitea user argocd not restored"
