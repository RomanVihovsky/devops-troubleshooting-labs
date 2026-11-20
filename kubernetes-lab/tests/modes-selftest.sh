#!/usr/bin/env bash
# Practice-mode self-run (Phase 7a): interview (fix + hint, then solution seen), chaos (ticket, fix, result),
# and the exam ticket choice. Needs the cluster; uses three quick ns-level labs. Output: .state/modes-selftest.out
#   tests/modes-selftest.sh            exits 0 when every check passed
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
OUT=.state/modes-selftest.out; : > "$OUT"
fails=0
step() { echo "== $*" | tee -a "$OUT"; }
expect() {   # expect <description> <grep -E pattern> <file>
  if grep -qE "$2" "$3"; then echo "  ok   $1" | tee -a "$OUT"; else echo "  FAIL $1 (no /$2/)" | tee -a "$OUT"; fails=$((fails + 1)); fi
}
refuse() {   # refuse <description> <grep -E pattern> <file>: the pattern must NOT appear
  if grep -qE "$2" "$3"; then echo "  FAIL $1 (/$2/ leaked)" | tee -a "$OUT"; fails=$((fails + 1)); else echo "  ok   $1" | tee -a "$OUT"; fi
}
fix() {   # apply the reference fix WITHOUT the reveal hook (what a student's own fix looks like)
  bash -c 'cd "$1"; source lib/common.sh; source lib/vm.sh; source lib/cluster.sh; source lib/upgrade.sh
    source lib/golden.sh; source lib/gitops.sh; source lib/scenario.sh; source lib/modes.sh
    d=$(current); export LAB_ID; LAB_ID=$(yget id "$d"); run_lab_script "$d/.lab/solve.sh" "$WS/$LAB_ID"' _ "$PWD"
}
t=$(mktemp -d)

step "interview: X03 then C03"
IV_PICK="X03 C03" ./lab interview 2 10 > "$t/1" 2>&1; cat "$t/1" >> "$OUT"
expect "interview started, ticket 1/2" 'Interview ticket 1/2' "$t/1"
refuse "no lab ID in the start output" 'X03|C03|namespace-label' "$t/1"
expect "ticket points at workspace/current" 'workspace/current' "$t/1"
[ -L workspace/current ] && echo "  ok   workspace/current is a symlink" | tee -a "$OUT" || { echo "  FAIL workspace/current missing" | tee -a "$OUT"; fails=$((fails + 1)); }
./lab list > "$t/2" 2>&1; refuse "list does not mark the hidden lab" '▶' "$t/2"
./lab status > "$t/3" 2>&1; cat "$t/3" >> "$OUT"; refuse "status hides the ID" 'X03' "$t/3"; expect "status shows the interview" 'Interview: ticket 1/2' "$t/3"
./lab hint > /dev/null 2>&1
fix >> "$OUT" 2>&1
./lab verify > "$t/4" 2>&1; cat "$t/4" >> "$OUT"
expect "verify PASS stops the clock" 'ticket 1/2 solved in' "$t/4"
refuse "verify output hides the ID" 'Verifying X03' "$t/4"
./lab interview next > "$t/5" 2>&1; cat "$t/5" >> "$OUT"
expect "ticket 2/2 started" 'Interview ticket 2/2' "$t/5"
./lab solution -y > "$t/6" 2>&1; expect "solution marks the ticket 0" 'scores 0' "$t/6"
./lab interview next > "$t/7" 2>&1; cat "$t/7" >> "$OUT"
expect "score card" 'Interview score card' "$t/7"
expect "X03 solved with 1 hint = 16/20" 'X03 .*solved .* 1 +16/20' "$t/7"
expect "C03 revealed = 0" 'C03 .*revealed .* 0/' "$t/7"
[ ! -e .state/interview ] && [ ! -e .state/current ] && echo "  ok   interview state and lab cleaned up" | tee -a "$OUT" || { echo "  FAIL leftovers" | tee -a "$OUT"; fails=$((fails + 1)); }

step "chaos: C01"
IV_PICK=C01 ./lab chaos start 1 > "$t/8" 2>&1; cat "$t/8" >> "$OUT"
expect "chaos banner" 'No ticket - find it' "$t/8"
refuse "no ticket and no ID shown" 'C01|INC-' "$t/8"
./lab ticket > "$t/9" 2>&1; expect "ticket costs 25 %" '25 %' "$t/9"
fix >> "$OUT" 2>&1
./lab verify > "$t/10" 2>&1; expect "chaos fixed" 'Chaos fixed in' "$t/10"
./lab chaos stop > "$t/11" 2>&1; cat "$t/11" >> "$OUT"
expect "chaos result: solved, ticket seen, 7/10" 'C01 .*solved .*ticket seen, hints 0: .*7/10' "$t/11"

step "exam: ticket choice (dry)"
bash -c 'source lib/common.sh; source lib/vm.sh; source lib/cluster.sh; source lib/upgrade.sh; source lib/golden.sh
  source lib/gitops.sh; source lib/scenario.sh; source lib/modes.sh; iv_pick_exam' > "$t/12"
cat "$t/12" >> "$OUT"
[ "$(wc -l < "$t/12")" = 8 ] && echo "  ok   8 exam tickets" | tee -a "$OUT" || { echo "  FAIL exam picked $(wc -l < "$t/12")" | tee -a "$OUT"; fails=$((fails + 1)); }
[ "$(cut -c1 "$t/12" | sort -u | wc -l)" -ge 7 ] && echo "  ok   spread over the domain groups" | tee -a "$OUT" || { echo "  FAIL exam domains" | tee -a "$OUT"; fails=$((fails + 1)); }

rm -rf "$t"
echo "== $fails failed" | tee -a "$OUT"
[ "$fails" = 0 ]
