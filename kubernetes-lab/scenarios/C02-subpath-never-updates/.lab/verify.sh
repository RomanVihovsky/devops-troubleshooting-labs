says() { local out; out=$(pods_get catalog app=catalog /); [ "$(grep -c "^$1 from" <<<"$out")" -ge 2 ] && ! grep -v "^$1 from" <<<"$out" | grep -q 'from'; }
uids() { kx -n catalog get pods -l app=catalog --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.uid}' | tr ' ' '\n' | sort | tr '\n' ' '; }
check_eventually 120 "every catalog pod says Bonjour" says Bonjour
if [ -z "${LAB_EXPECT_FAIL:-}" ] && says Bonjour; then
  before=$(uids); r0=$(restarts catalog app=catalog)
  kx -n catalog patch configmap catalog-files --type merge -p '{"data":{"app.conf":"# re-read by labapp on every request\ngreeting = Hola\n"}}' >/dev/null
  check_eventually 150 "a new edit (greeting = Hola) reaches every pod" says Hola
  check "...without restarting or replacing a pod" test "$(uids)|$(restarts catalog app=catalog)" = "$before|$r0"
fi
verdict
