# CPU used by the whole machine over 5 s, in % of one core (from the cgroup, not ps averages)
cpu_pct_5s() {
  sx 'a=$(awk "/usage_usec/{print \$2}" /sys/fs/cgroup/cpu.stat); sleep 5
      b=$(awk "/usage_usec/{print \$2}" /sys/fs/cgroup/cpu.stat); echo $(( (b - a) / 50000 ))'
}
no_hog_70s() {
  local i
  for i in $(seq 13); do
    sx 'pgrep -f "^\[kmetricsd\]"' >/dev/null && return 1
    [ "$(cpu_pct_5s)" -lt 50 ] || return 1
  done
}
check "cron is running" active cron
check "no CPU hog for 65 s (takes a while...)" no_hog_70s
verdict
