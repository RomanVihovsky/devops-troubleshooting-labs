#!/bin/bash
# health-watch.sh <logfile> <lab-vm-ip>
# Every 10 s on the desktop VM: load, available memory, a journal write/read-back probe, and
# whether the lab VM answers ping. Log only - the lab VM is a separate VirtualBox VM.
log=$1 vm=$2 n=0
while true; do
  n=$((n + 1))
  load=$(cut -d' ' -f1 /proc/loadavg)
  avail=$(awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo)
  logger -t k8slab-probe "probe-$n"; sleep 1
  journalctl -t k8slab-probe --since "-20s" -o cat 2>/dev/null | grep -qx "probe-$n" && j=ok || j=FAIL
  ping -c1 -W2 "$vm" >/dev/null 2>&1 && p=up || p=DOWN
  echo "$(date +%T) load=$load memavail=${avail}M journal=$j labvm=$p" >> "$log"
  sleep 9
done
