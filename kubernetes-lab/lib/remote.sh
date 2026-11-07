# shellcheck shell=bash
# The lab VM is a *sibling* VirtualBox VM (see docs/LAB-VM-SETUP.md). Everything privileged
# (Docker, kind, iptables...) runs there; this desktop VM only talks to it over SSH.
LAB_VM_HOST=${LAB_VM_HOST:-192.168.56.20}
LAB_VM_USER=${LAB_VM_USER:-lab}
LAB_VM_KEY="$STATE_DIR/labvm_key"

ssh_opts() {
  echo -i "$LAB_VM_KEY" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$STATE_DIR/known_hosts" \
       -o LogLevel=ERROR -o ConnectTimeout=5 -o ServerAliveInterval=15 -o BatchMode=yes
}
# vx '<cmd>'   run a command on the lab VM;   vxi   run a bash script from stdin there
# shellcheck disable=SC2046
vx()  { ssh $(ssh_opts) "$LAB_VM_USER@$LAB_VM_HOST" "$@"; }
# shellcheck disable=SC2046
vxi() { ssh $(ssh_opts) "$LAB_VM_USER@$LAB_VM_HOST" bash -s; }
# vcp <local> <remote-path>
# shellcheck disable=SC2046
vcp() { scp -q $(ssh_opts) "$1" "$LAB_VM_USER@$LAB_VM_HOST:$2"; }

vm_reachable() { vx true >/dev/null 2>&1; }

vm_check() {
  local ok_=1
  ip -4 -br addr | grep -q '192\.168\.56\.' && ok "desktop VM has a host-only address" \
    || { warn "desktop VM has no 192.168.56.x address (Adapter 2 = Host-only missing?)"; ok_=0; }
  if vm_reachable; then
    ok "lab VM reachable: $(vx 'echo "$(hostname), $(nproc) vCPU, $(free -g | awk "/Mem/{print \$2}") GiB RAM, $(df -h / | awk "NR==2{print \$4}") free on /"')"
    vx 'sudo -n true' 2>/dev/null && ok "passwordless sudo works" || { warn "sudo asks for a password (see LAB-VM-SETUP.md step 4)"; ok_=0; }
    vx '[ -e /dev/kvm ] && echo nested-virt-visible || echo no-nested-virt' | grep -q no-nested-virt \
      && ok "nested virtualization is off in the lab VM" || warn "lab VM sees /dev/kvm - nested AMD-V is still on (turn it off)"
  else
    warn "cannot ssh lab@$LAB_VM_HOST with .state/labvm_key"; ok_=0
  fi
  [ $ok_ = 1 ]
}

vm_provision() {
  source "$LAB_DIR/versions.env"
  info "Copying kind $KIND_VERSION and kubectl $KUBECTL_VERSION to the lab VM"
  vcp "$LAB_DIR/cache/kind" /tmp/kind
  vcp "$LAB_DIR/cache/kubectl" /tmp/kubectl
  info "Installing Docker + tools on the lab VM (apt)"
  KIND_NODE_IMAGE="$KIND_NODE_IMAGE" vxi < "$LAB_DIR/infra/provision.sh"
  info "Pulling the kind node image (retries; Docker Hub can be flaky)"
  vx "for i in 1 2 3 4 5 6; do docker pull -q '$KIND_NODE_IMAGE' && exit 0; sleep 10; done; exit 1"
  ok "lab VM provisioned"
}

# Host-health watch on THIS desktop VM while the lab VM works (log only - the lab VM is a sibling).
health_start() {
  systemctl --user reset-failed k8slab-health 2>/dev/null || true
  systemctl --user is-active --quiet k8slab-health && return 0
  systemd-run --user --quiet --unit=k8slab-health --collect \
    bash "$LAB_DIR/lib/health-watch.sh" "$STATE_DIR/health.log" "$LAB_VM_HOST"
}
health_stop() { systemctl --user stop k8slab-health 2>/dev/null || true; }
