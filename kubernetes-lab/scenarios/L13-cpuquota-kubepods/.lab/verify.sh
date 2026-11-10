uncapped() { nx k8s-w1 'cat /sys/fs/cgroup/kubepods.slice/cpu.max' </dev/null | grep -q '^max '; }
no_persistent() {
  ! nx k8s-w1 'grep -rqs CPUQuota=. /etc/systemd/system.control/kubepods.slice.d /etc/systemd/system/kubepods.slice.d /run/systemd/system.control/kubepods.slice.d' </dev/null
}
check "kubepods.slice cpu.max = max on k8s-w1" uncapped
check "no CPUQuota drop-in left for kubepods.slice (survives a reboot)" no_persistent
check_eventually 200 "search pods Ready with no new restarts for 60 s" stable_for 60 search app=search
verdict
