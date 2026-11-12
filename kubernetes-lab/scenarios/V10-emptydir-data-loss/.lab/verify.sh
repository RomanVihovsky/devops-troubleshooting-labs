survives() {
  local m="note-$RANDOM" p
  p=$(kx -n notes get pods -l app=notes --field-selector=status.phase=Running -o name | head -1); [ -n "$p" ] || return 1
  kx -n notes exec "$p" -- sh -c "echo $m > /data/verify-note" >/dev/null 2>&1 || return 1
  kx -n notes delete "$p" --wait=true >/dev/null 2>&1
  wait_rollout notes deploy/notes 120 || return 1
  p=$(kx -n notes get pods -l app=notes --field-selector=status.phase=Running -o name | head -1)
  [ "$(kx -n notes exec "$p" -- cat /data/verify-note 2>/dev/null)" = "$m" ]
}
check_eventually 60 "notes Ready" deploy_ready notes notes
check "a file in /data survives deleting the pod" survives
verdict
