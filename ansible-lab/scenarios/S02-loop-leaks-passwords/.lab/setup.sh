mkdir -p .onboarding
p1="Init-$(od -An -tx1 -N6 /dev/urandom | tr -d ' \n')"; p2="Init-$(od -An -tx1 -N6 /dev/urandom | tr -d ' \n')"
remember pw_alice "$p1"; remember pw_bob "$p2"
printf '[\n  {"name": "alice", "full_name": "Alice Ng", "password": "%s"},\n  {"name": "bob", "full_name": "Bob Ortiz", "password": "%s"}\n]\n' "$p1" "$p2" > .onboarding/users.json
ws_commit "onboarding from the HR export"
run_logged "$SETUP_LOG" ctl "sh ci/deploy.sh"
