registry() { nx lb1 "lb-register list" | awk '{print $1}' | sort | xargs; }
up_servers() {
  nx lb1 "echo 'show stat' | socat stdio /run/haproxy/admin.sock" | awk -F, '$1 == "web" && $2 ~ /^web/ && $18 ~ /^UP/ {print $2}' | sort | xargs
}
one_deploy_registers_all() {
  nx lb1 "lb-register reset" >> "$VERIFY_LOG" 2>&1
  applies deploy.yml
  echo "registry after one deploy: [$(registry)]" >> "$VERIFY_LOG"
  [ "$(registry)" = "web1 web2 web3" ]
}
all_up() { [ "$(up_servers)" = "web1 web2 web3" ]; }
tool_unchanged() { untouched files/lb-register && [ "$(nx lb1 'sha256sum /usr/local/sbin/lb-register' | cut -d' ' -f1)" = "$(recall lbsha)" ]; }
parallel() {
  ! grep -qE '^ {2,4}(serial|throttle):' "$CI/deploy.yml" &&
    ctl_ci "ansible-config dump -t base" | grep -E '^DEFAULT_FORKS\(' | grep -qvE '= 1$'
}
check "from an empty registry, one deploy registers web1 web2 web3" one_deploy_registers_all
check_eventually 15 "haproxy on lb1 has web1, web2 and web3 UP" all_up
check "lb-register (the network team's tool) is unchanged - in the repo and on lb1" tool_unchanged
check "the deploy is not serialized (no play-level serial/throttle, forks > 1)" parallel
check "a second deploy changes nothing (check mode)" converged deploy.yml
verdict
