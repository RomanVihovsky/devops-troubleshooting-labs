ee_ok() {
  docker image inspect acme/ee:1 >/dev/null 2>&1 &&
    docker run --rm acme/ee:1 ansible --version | head -1 | grep -q 'core 2.22.0' &&
    docker run --rm acme/ee:1 python3 -c 'import jmespath' 2>>"$VERIFY_LOG"
}
ee_converges() {
  docker run --rm --network "$NET" --user "$(id -u):0" -v "$CI:/runner/project" -v "$SSH_DIR:/runner/.ssh:ro" \
    -w /runner/project -e ANSIBLE_STDOUT_CALLBACK=ansible.posix.json acme/ee:1 \
    ansible-playbook site.yml --check > "$CI/.lab-ap.json" 2>>"$VERIFY_LOG"
  stats_ok '.changed == 0 and .failures == 0 and .unreachable == 0'
}
check "image acme/ee:1 exists with ansible-core 2.22.0 and jmespath" ee_ok
check "/etc/acme/services.txt on web1 lists shop,api" test "$(nx web1 'cat /etc/acme/services.txt' 2>/dev/null)" = "shop,api"
check "site.yml converges when run inside the EE" ee_converges
check "the EE definition is version 3 and declares jmespath" eval 'grep -qE "^version: *3" "$CI/ee/execution-environment.yml" && grep -q jmespath "$CI/ee/execution-environment.yml"'
verdict
