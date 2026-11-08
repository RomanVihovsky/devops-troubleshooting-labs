release() {   # release <version>: run ci/release.sh in CI, JSON output
  local v=$1 rc=0; local args=(); mapfile -t args < <(ctl_env_args)
  docker exec -u ops -w /ci -e ANSIBLE_STDOUT_CALLBACK=ansible.posix.json -e ANSIBLE_NOCOLOR=1 "${args[@]}" \
    "$CTL" sh ci/release.sh -e "app_version=$v" > "$CI/.lab-ap.raw" 2>> "$VERIFY_LOG" || rc=$?
  sed -n '/^{$/,/^}$/p' "$CI/.lab-ap.raw" > "$CI/.lab-ap.json"; return $rc
}
new_release() {
  local v="1.6.$RANDOM"
  release "$v" && nx app1 "grep -qx '$v' /opt/app/VERSION && grep -qx 'version = $v' /opt/app/app.ini"
}
check "ci/release.sh puts a new version on app1" new_release
check "the release job doesn't run Base packages" eval '[ -z "$(task_result "Base packages")" ]'
check "ci/release.sh still uses --tags deploy" eval 'grep -q -- "--tags deploy" "$CI/ci/release.sh"'
check "release 1.5.0 is on app1 (full run converges)" eval 'applies site.yml && nx app1 "grep -qx 1.5.0 /opt/app/VERSION" && converged site.yml'
verdict
