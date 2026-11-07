stable_40s() {
  local a b
  active data-indexer || return 1
  a=$(restarts data-indexer); sleep 40; b=$(restarts data-indexer)
  [ "$a" = "$b" ] && active data-indexer
}
check "MemoryMax is still 96M" sx '[ "$(systemctl show -p MemoryMax --value data-indexer)" = "100663296" ]'
check "data-indexer runs 40 s without a restart (takes 40 s...)" stable_40s
verdict
