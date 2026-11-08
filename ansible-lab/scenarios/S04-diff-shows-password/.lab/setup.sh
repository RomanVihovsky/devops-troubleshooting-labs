rh() { od -An -tx1 -N8 /dev/urandom | tr -d ' \n'; }
mkdir -p .secrets
old="dbpw-$(rh)"; remember old_pw "$old"
printf '{"user": "acme_app", "password": "%s"}\n' "$old" > .secrets/db.json
ap site.yml
ws_commit "DB client config from the secret store export"
new="dbpw-$(rh)"; remember new_pw "$new"
printf '{"user": "acme_app", "password": "%s"}\n' "$new" > .secrets/db.json
run_logged "$SETUP_LOG" ctl "sh ci/pr-check.sh"
