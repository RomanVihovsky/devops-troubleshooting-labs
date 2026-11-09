#!/usr/bin/env bash
# k8slab.sh - create and manage the kubernetes-lab node VMs on a Linux or macOS VirtualBox host.
# Windows hosts use k8slab.bat (same commands). Run it from the kit folder made by `./lab vm kit`.
# It only ever touches the VMs listed in nodes.csv (k8s-*); everything inside the VMs is done by ./lab.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
VBM=${VBOXMANAGE:-VBoxManage}
K8SLAB_HOME=${K8SLAB_HOME:-$HOME/k8slab}

while IFS='=' read -r k v; do                       # kit.env: KEY=value, no quotes (shared with the .bat)
  k=${k%$'\r'}; v=${v%$'\r'}
  case $k in ''|\#*) continue ;; esac
  printf -v "$k" '%s' "$v"
done < "$KIT/kit.env"
VDI="$K8SLAB_HOME/base/$BASE_DISK"
SEED="$K8SLAB_HOME/base/seed.iso"

say()  { echo "==> $*"; }
warn() { echo "!   $*" >&2; }
die()  { echo "ERROR: $*" >&2; exit 1; }
vbm()  { "$VBM" "$@"; }

usage() {
  cat <<U
k8slab.sh - the kubernetes-lab node VMs (VirtualBox $VM_GROUP)
  check                      VirtualBox version, host-only network $HOSTONLY_IP, free disk
  create [nodes]             download + verify the Ubuntu image once, create and boot the VMs
  start|stop [nodes]         start headless / ACPI shutdown (power off after 90 s)
  status                     state, IP and current snapshot of every node
  snapshot <name> [nodes]    stop, snapshot (replaces one of the same name), start
  restore <name> [nodes]     power off, restore the snapshot, start
  destroy [nodes]            power off and delete the VMs and their disks (asks first)
nodes: names from nodes.csv (k8s-cp1 or just cp1). Default: all of them except role "spare".
Files and VMs: $K8SLAB_HOME (override with K8SLAB_HOME=...)
U
}

# rows -> "name cpus mem ip mac1 mac2 role" per node
rows() { while IFS=, read -r n c m ip m1 m2 r; do
           case $n in ''|\#*) continue ;; esac
           echo "$n $c $m $ip $m1 $m2 ${r%$'\r'}"
         done < "$KIT/nodes.csv"; }
row()  { rows | awk -v n="$1" '$1 == n'; }

# select <mode> <args...>: echo the chosen node names (create mode skips spares by default)
select_nodes() {
  local mode=$1 a n; shift
  if [ $# -eq 0 ] || [ "$*" = all ]; then
    rows | awk -v m="$mode" 'm != "create" || $7 != "spare" {print $1}'; return
  fi
  for a in "$@"; do
    n=$a; [[ $n == k8s-* ]] || n="k8s-$n"
    [ -n "$(row "$n")" ] || die "unknown node: $a (see nodes.csv)"
    echo "$n"
  done
}

exists() { vbm showvminfo "$1" --machinereadable >/dev/null 2>&1; }
state()  { { vbm showvminfo "$1" --machinereadable 2>/dev/null || true; } | sed -n 's/^VMState="\(.*\)"$/\1/p'; }

hostonly_name() {   # the host-only adapter (Linux) / network (macOS) that owns $HOSTONLY_IP
  if [ "$(uname -s)" = Darwin ]; then
    vbm list hostonlynets | awk -F': *' -v n="$HOSTONLY_NET" '!f && $1=="Name" && $2==n {print n; f=1}'
  else
    vbm list hostonlyifs | awk -F': *' -v ip="$HOSTONLY_IP" '$1=="Name"{n=$2} !f && $1=="IPAddress" && $2==ip {print n; f=1}'
  fi
}

cmd_check() {
  local v free ho
  v=$(vbm --version) || die "VBoxManage not found (set VBOXMANAGE=/path/to/VBoxManage)"
  echo "VirtualBox $v"
  [ "${v%%.*}" -ge 7 ] || die "VirtualBox 7.0 or newer is required"
  ARCH=()                                   # VirtualBox 7.1+ requires the platform architecture on createvm
  if [ "${v%%.*}" -gt 7 ] || { v=${v#*.}; [ "${v%%.*}" -ge 1 ]; }; then ARCH=(--platform-architecture x86); fi
  ho=$(hostonly_name)
  if [ -n "$ho" ]; then echo "host-only network: $ho ($HOSTONLY_IP)"
  elif [ "$(uname -s)" = Darwin ]; then
    die "no host-only network '$HOSTONLY_NET' - create it: VBoxManage hostonlynet add --name $HOSTONLY_NET --netmask 255.255.255.0 --lower-ip 192.168.56.100 --upper-ip 192.168.56.199 --enable"
  else die "no host-only adapter with IP $HOSTONLY_IP - create one (File > Tools > Network Manager), 192.168.56.1/24"; fi
  mkdir -p "$K8SLAB_HOME"
  free=$(df -Pk "$K8SLAB_HOME" | awk 'NR==2{print int($4/1048576)}')
  echo "free disk at $K8SLAB_HOME: ${free} GB (VMs go to $K8SLAB_HOME/vms)"
  [ "$free" -ge 50 ] || warn "less than 50 GB free - the 5 VMs need about 40 GB"
  if lsmod 2>/dev/null | grep -q '^kvm'; then warn "the kvm module is loaded - VirtualBox and KVM can't both use VT-x/AMD-V"; fi
  echo "OK"
}

sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }

ensure_base() {
  local img="$K8SLAB_HOME/cache/$IMAGE_FILE" sum
  mkdir -p "$K8SLAB_HOME"/{cache,base,disks,logs,vms}
  if [ ! -f "$VDI" ]; then
    if [ ! -f "$img" ]; then
      say "downloading $IMAGE_URL (~600 MB, once)"
      curl -fL --retry 3 -C - -o "$img.part" "$IMAGE_URL"; mv "$img.part" "$img"
    fi
    sum=$(sha256 "$img")
    [ "$sum" = "$IMAGE_SHA256" ] || { rm -f "$img"; die "checksum mismatch for $img (got $sum) - deleted, run create again"; }
    say "image verified; converting to $VDI"
    vbm clonemedium disk "$img" "$VDI" --format VDI >/dev/null
    vbm closemedium disk "$img" >/dev/null 2>&1 || true
    vbm modifymedium disk "$VDI" --resize "$DISK_MB" >/dev/null
  fi
  if ! cmp -s "$KIT/seed.iso" "$SEED"; then cp "$KIT/seed.iso" "$SEED" || warn "could not update $SEED"; fi
}

create_vm() {   # name cpus mem ip mac1 mac2 role
  local n=$1 nic2
  if exists "$n"; then echo "   $n: exists, skipped"; return; fi
  if [ "$(uname -s)" = Darwin ]; then nic2=(--nic2 hostonlynet --host-only-net2 "$HOSTONLY")
  else nic2=(--nic2 hostonly --host-only-adapter2 "$HOSTONLY"); fi
  say "$n: $2 vCPU, $3 MB, $4"
  # --basefolder: never VirtualBox's default machine folder, which may point somewhere this user can't write
  vbm createvm --name "$n" ${ARCH[@]+"${ARCH[@]}"} --ostype Ubuntu_64 --groups "$VM_GROUP" \
    --basefolder "$K8SLAB_HOME/vms" --register >/dev/null
  if ! configure_vm "$@"; then
    vbm unregistervm "$n" --delete >/dev/null 2>&1 || true
    die "creating $n failed - removed the half-made VM, so create can run again"
  fi
}
configure_vm() {   # same args as create_vm; every step must succeed (set -e is off in an if)
  local n=$1
  vbm modifyvm "$n" --cpus "$2" --memory "$3" --vram 16 --graphicscontroller vmsvga \
    --firmware bios --ioapic on --rtc-use-utc on --nested-hw-virt off --paravirt-provider default \
    --boot1 disk --boot2 dvd --boot3 none --boot4 none \
    --audio-enabled off --usb-ohci off --usb-ehci off --usb-xhci off \
    --clipboard-mode disabled --drag-and-drop disabled \
    --nic1 nat --nic-type1 82540EM --mac-address1 "$5" \
    "${nic2[@]}" --nic-type2 82540EM --mac-address2 "$6" \
    --uart1 0x3F8 4 --uart-mode1 file "$K8SLAB_HOME/logs/$n-console.log" || return 1
  vbm storagectl "$n" --name SATA --add sata --controller IntelAhci --portcount 2 --hostiocache on || return 1
  # each VM gets its own full copy of the base disk (VBoxManage can't make a new disk multiattach on 7.2)
  local disk="$K8SLAB_HOME/disks/$n.vdi"
  if [ -e "$disk" ]; then vbm closemedium disk "$disk" --delete >/dev/null 2>&1 || rm -f "$disk"; fi
  vbm clonemedium disk "$VDI" "$disk" --format VDI >/dev/null || return 1
  vbm storageattach "$n" --storagectl SATA --port 0 --device 0 --type hdd --medium "$disk" || return 1
  vbm storageattach "$n" --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$SEED" || return 1
  vbm startvm "$n" --type headless >/dev/null || return 1
}

start_vm() {
  case $(state "$1") in
    '') echo "   $1: not created" ;;
    running) echo "   $1: running" ;;
    paused) vbm controlvm "$1" resume ;;
    *) vbm startvm "$1" --type headless >/dev/null && echo "   $1: started" ;;
  esac
}

stop_send() { if [ "$(state "$1")" = running ]; then vbm controlvm "$1" acpipowerbutton 2>/dev/null || true; fi; }
stop_wait() {
  local _ s
  for _ in $(seq 45); do
    s=$(state "$1")
    case $s in ''|poweroff|aborted|saved) [ -n "$s" ] && echo "   $1: $s"; return ;; esac
    sleep 2
  done
  warn "$1: no ACPI shutdown after 90 s - powering off"; vbm controlvm "$1" poweroff >/dev/null 2>&1 || true; sleep 3
}
stop_all() { local n; for n in "$@"; do stop_send "$n"; done; for n in "$@"; do stop_wait "$n"; done; }

cmd_status() {
  local n c m ip m1 m2 r s snap
  printf '%-9s %-15s %-11s %-13s %s\n' NODE IP STATE ROLE SNAPSHOT
  while read -r n c m ip m1 m2 r; do
    s=$(state "$n"); snap=""
    if [ -n "$s" ]; then
      snap=$({ vbm snapshot "$n" list --machinereadable 2>/dev/null || true; } | sed -n 's/^CurrentSnapshotName="\(.*\)"$/\1/p')
    fi
    printf '%-9s %-15s %-11s %-13s %s\n' "$n" "$ip" "${s:-not created}" "$r" "${snap:--}"
  done < <(rows)
}

snap_name() { [[ ${1:-} =~ ^[A-Za-z0-9._-]+$ ]] || die "usage: k8slab.sh $2 <name> [nodes]   (name: letters, digits, . _ -)"; }

# pick <mode> [nodes]: set SEL to the chosen node names (dies on an unknown name)
pick() { local out; out=$(select_nodes "$@"); read -r -d "" -a SEL <<<"$out" || true; }
# keep only the nodes that exist as VMs
only_created() { local n out=(); for n in "${SEL[@]}"; do exists "$n" && out+=("$n"); done; SEL=(${out[@]+"${out[@]}"}); }

main() {
  local cmd=${1:-help} name n ans; [ $# -gt 0 ] && shift
  local -a r
  SEL=()
  case $cmd in
    check) cmd_check ;;
    create)
      pick create "$@"
      cmd_check; HOSTONLY=$(hostonly_name)
      ensure_base
      for n in "${SEL[@]}"; do read -r -a r <<<"$(row "$n")"; create_vm "${r[@]}"; done
      say "booting - first boot takes 1-2 min. Then, on the desktop VM:  ./lab vm wait" ;;
    start) pick any "$@"; for n in "${SEL[@]}"; do start_vm "$n"; done ;;
    stop)  pick any "$@"; only_created; [ ${#SEL[@]} -eq 0 ] || stop_all "${SEL[@]}" ;;
    status) cmd_status ;;
    snapshot|restore)
      name=${1:-}; snap_name "$name" "$cmd"; shift
      pick any "$@"; only_created
      [ ${#SEL[@]} -gt 0 ] || die "no VMs created yet"
      if [ "$cmd" = snapshot ]; then
        stop_all "${SEL[@]}"
        for n in "${SEL[@]}"; do
          if vbm snapshot "$n" showvminfo "$name" >/dev/null 2>&1; then vbm snapshot "$n" delete "$name"; fi
          vbm snapshot "$n" take "$name" --description "kubernetes-lab $(date '+%F %T')" >/dev/null
          echo "   $n: snapshot $name taken"
        done
      else
        for n in "${SEL[@]}"; do
          vbm snapshot "$n" showvminfo "$name" >/dev/null 2>&1 || die "$n has no snapshot named $name"
        done
        for n in "${SEL[@]}"; do [ "$(state "$n")" != running ] || vbm controlvm "$n" poweroff >/dev/null 2>&1 || true; done
        for n in "${SEL[@]}"; do stop_wait "$n" >/dev/null; vbm snapshot "$n" restore "$name" >/dev/null; echo "   $n: restored $name"; done
      fi
      for n in "${SEL[@]}"; do start_vm "$n"; done ;;
    destroy)
      pick any "$@"; only_created
      [ ${#SEL[@]} -gt 0 ] || { echo "nothing to destroy"; return; }
      read -r -p "Delete ${SEL[*]} and their disks? [y/N] " ans
      case $ans in y|Y) ;; *) die "aborted" ;; esac
      for n in "${SEL[@]}"; do
        vbm controlvm "$n" poweroff >/dev/null 2>&1 || true; stop_wait "$n" >/dev/null
        vbm unregistervm "$n" --delete && echo "   $n: deleted"
      done
      echo "The base disk and the image stay in $K8SLAB_HOME (delete that folder to remove everything)." ;;
    help|-h|--help) usage ;;
    *) usage; exit 1 ;;
  esac
}
main "$@"
