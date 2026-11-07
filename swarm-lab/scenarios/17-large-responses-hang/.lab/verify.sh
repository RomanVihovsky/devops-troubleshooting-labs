big_ok() {
  local n i
  for n in "${BASE_NODES[@]}"; do
    for i in 1 2 3; do HTTP_TIMEOUT=8 http "$n" '/big?kb=512' -o /dev/null || return 1; done
  done
}
check_eventually 30 "/big?kb=512 completes via every node" big_ok
verdict
