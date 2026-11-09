replicas_as_git() { [ "$(kx -n demo get deploy demo -o jsonpath='{.spec.replicas}')" = 2 ]; }
no_hotfix_env() { ! kx -n demo get deploy demo -o jsonpath='{.spec.template.spec.containers[0].env[*].name}' | grep -qw GREETING; }
freeze_in_git() { gx "/repos/lab/gitops/raw/apps/demo.yaml?ref=main" | grep -q 'selfHeal: false'; }
history_kept() { gx "/repos/lab/gitops/commits?sha=main&limit=30" | jq -e '[.[] | select(.commit.message | test("change freeze"))] | length > 0' >/dev/null; }
check_eventually 120 "Argo CD app demo Synced + Healthy" argo_app_ok demo
check "demo runs the 2 replicas Git declares" replicas_as_git
check "the hand-made GREETING env var is gone" no_hotfix_env
check "the freeze is still in Git (selfHeal: false on main)" freeze_in_git
check "Git history kept (the freeze commit is still on main)" history_kept
verdict
