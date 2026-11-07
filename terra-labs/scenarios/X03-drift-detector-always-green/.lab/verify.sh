drift_rc() { local rc=0; (cd "$CI" && timeout 300 ./ci/drift.sh payments) >> "$VERIFY_LOG" 2>&1 || rc=$?; echo $rc; }
cycle() {
  local now; now=$(ssm_value /payments/max-transaction-eur)
  aws ssm put-parameter --name /payments/max-transaction-eur --type String --value 50000 --overwrite >/dev/null
  local a; a=$(drift_rc)
  aws ssm put-parameter --name /payments/max-transaction-eur --type String --value 5000 --overwrite >/dev/null
  local b; b=$(drift_rc)
  aws ssm put-parameter --name /payments/max-transaction-eur --type String --value "$now" --overwrite >/dev/null
  echo "drift rc with change=$a, without=$b" >> "$VERIFY_LOG"
  [ "$a" = 2 ] && [ "$b" = 0 ]
}
check "drift.sh: 2 with the hand-made change, 0 without" cycle
verdict
