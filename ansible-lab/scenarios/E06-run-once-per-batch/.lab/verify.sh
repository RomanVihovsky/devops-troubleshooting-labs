v="3.3.$RANDOM"
deploy() { applies site.yml -e "app_version=$v"; }
migrated_once() { [ "$(nx db1 "grep -c ' migrate $v\$' /var/lib/acme/migrations.log")" = 1 ]; }
before_rollout() {   # the migration task's first appearance precedes the first release install
  jq -e --arg v "$v" '[.plays[].tasks[] | .task.name] as $t | ($t | index("Run DB migrations")) < ($t | index("Install the release"))' "$CI/.lab-ap.json" >/dev/null
}
check "a new release deploys" deploy
check "its migration ran exactly once" migrated_once
check "the migration ran before any app node got the release" before_rollout
check "both app nodes have the release" eval 'nx app1 "grep -qx $v /opt/app/VERSION" && nx app2 "grep -qx $v /opt/app/VERSION"'
check "the app rollout is still serial" eval 'grep -qE "^ *serial: *(1|\"?[0-9]+%?\"?)" "$CI/site.yml"'
verdict
