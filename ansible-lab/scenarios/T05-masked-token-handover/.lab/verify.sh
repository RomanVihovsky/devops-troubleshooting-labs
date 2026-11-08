tok=$(recall token)
b64=$(printf %s "$tok" | base64 | tr -d '=')
pipeline_ok() { ctl_ci "sh ci/pipeline.sh" > "$CI/.lab-pipeline.out" 2>&1; local rc=$?; cat "$CI/.lab-pipeline.out" >> "$VERIFY_LOG"; [ $rc = 0 ] && grep -q '^ok$' "$CI/.lab-pipeline.out"; }
no_leak() { ! grep -qF -e "$tok" -e "$b64" "$CI/.lab-pipeline.out"; }
token_files_safe() {
  local f
  while IFS= read -r f; do
    case $f in */.lab-*) continue ;; esac
    [ "$(stat -c %a "$f")" = 600 ] || { echo "mode $(stat -c %a "$f"): $f" >> "$VERIFY_LOG"; return 1; }
    git -C "$CI" ls-files --error-unmatch "${f#"$CI"/}" >/dev/null 2>&1 && { echo "committed: $f" >> "$VERIFY_LOG"; return 1; }
  done < <(grep -rlF "$tok" "$CI" --exclude-dir=.git 2>/dev/null)
  return 0
}
check "ci/pipeline.sh passes the smoke test" pipeline_ok
check "the token is not in the CI output (plain or base64)" no_leak
check "files holding the token are 0600 and not committed" token_files_safe
check "vault file still encrypted" vault_encrypted "$CI/group_vars/all/vault.yml"
check "deploy.yml converges on the web tier" converged deploy.yml --limit web
verdict
