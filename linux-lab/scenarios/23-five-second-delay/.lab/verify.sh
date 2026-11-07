fast3() {
  local i t
  for i in 1 2 3; do
    t=$(sx "curl -fs -o /dev/null -w '%{time_total}' --max-time 8 http://api.internal:8080/") || return 1
    awk -v t="$t" 'BEGIN{exit !(t < 1.0)}' || return 1
  done
}
check "curl http://api.internal:8080/ answers in < 1 s, 3 times" fast3
verdict
