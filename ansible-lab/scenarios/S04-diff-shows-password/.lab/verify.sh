old=$(recall old_pw); new=$(recall new_pw)
rot="dbpw-verify-$RANDOM$RANDOM"
rotated() { printf '{"user": "acme_app", "password": "%s"}\n' "$1" > "$CI/.secrets/db.json"; }
pr_text_clean() {
  ctl_ci "sh ci/pr-check.sh" > "$CI/.lab-pr.out" 2>&1 || { cat "$CI/.lab-pr.out" >> "$VERIFY_LOG"; return 1; }
  ! grep -qF -e "$rot" -e "$new" -e "$old" "$CI/.lab-pr.out" && grep -q 'changed: \[app1\]' "$CI/.lab-pr.out"
}
pr_json_clean() {
  ap_json site.yml --check --diff && ! grep -qF -e "$rot" -e "$new" -e "$old" "$CI/.lab-ap.json" \
    && task_result "DB client config" | jq -e '.app1.changed == true' >/dev/null
}
# the node holds the current password ($new); the PR rotates to $rot
check "real deploy writes the current password" eval 'applies site.yml && nx app1 "cat /etc/acme/db.ini" | grep -qx "password = $new"'
rotated "$rot"
check "PR check output (text) shows no password, still reports the change" pr_text_clean
check "PR check output (JSON) shows no password, DB client config changed" pr_json_clean
rotated "$new"
check "site.yml converges" converged site.yml
verdict
