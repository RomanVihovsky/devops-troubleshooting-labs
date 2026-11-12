source "$SCN/.lab/facts.sh"
check "container" answered container "$(q02_restarted)"
check "reason" answered reason "$(q02_field reason)"
check "exit code" answered exit_code "$(q02_field exitCode)"
check "memory limit" answered memory_limit "$(q02_limit)"
check "the workload is unchanged (1 restart, same pod)" test "$(kx -n nightly get pods -l app=reporting --no-headers | wc -l)" = 1
verdict
