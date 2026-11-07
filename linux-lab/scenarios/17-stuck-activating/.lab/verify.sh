stable_25s() {
  local a b
  active cachewarm || return 1
  a=$(restarts cachewarm); sleep 25; b=$(restarts cachewarm)
  [ "$a" = "$b" ] && active cachewarm
}
check_eventually 20 "cachewarm is active" active cachewarm
check "no restarts for 25 s (takes 25 s...)" stable_25s
check "curl localhost:8084/ answers" sx 'curl -fs localhost:8084/'
verdict
