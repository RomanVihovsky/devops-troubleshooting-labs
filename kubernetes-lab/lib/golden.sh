# shellcheck shell=bash disable=SC2029,SC2016,SC2034,SC2119,SC2120
# Golden baseline + in-guest reset. The golden lives on the DESKTOP (.state/golden), never on the nodes, so
# nothing there spoils a scenario. Reset levels: node (files + runtime faults + pods of one node) and
# cluster (every node + etcd snapshot restore + gw configs). See PLAN.md "Reset ladder".

GOLDEN_DIR="$STATE_DIR/golden"
# managed paths on the Kubernetes nodes (whole directories are replaced, so rogue files disappear too)
NODE_PATHS="/etc/kubernetes /var/lib/kubelet/config.yaml /var/lib/kubelet/kubeadm-flags.env /var/lib/kubelet/pki
/etc/containerd /etc/cni/net.d /usr/lib/systemd/system/kubelet.service.d /etc/systemd/system/kubelet.service.d
/etc/default/kubelet /etc/sysctl.d /etc/modules-load.d /etc/fstab /etc/hosts /etc/chrony /etc/crictl.yaml
/etc/apt/sources.list.d/k8slab.list"
GW_PATHS="/etc/haproxy /etc/chrony /etc/exports.d /etc/nginx/sites-available/k8slab /etc/k8slab /etc/hosts
/etc/openbao /var/lib/openbao /etc/gitea /var/lib/gitea"
GW_STATEFUL="openbao k8slab-gitea"   # stopped while their data is copied / restored
ETCD_FLAGS="--endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"

# ---------------------------------------------------------------- golden ----
cluster_golden() {
  local n new="$GOLDEN_DIR.new"
  ensure_tools
  [ "${1:-}" = --force ] || cluster_doctor || die "doctor must PASS before taking the golden (or: ./lab cluster golden --force)"
  rm -rf "$new"; mkdir -p "$new"
  info "golden: node files, etcd snapshot, gw configs -> $(rel "$GOLDEN_DIR")"
  for n in $(cluster_nodes); do
    nx "$n" "tar -czf - --ignore-failed-read $(echo "$NODE_PATHS" | tr '\n' ' ') 2>/dev/null" </dev/null > "$new/$n.tgz"
    nx "$n" "dpkg-query -W -f '\${Package}=\${Version}\n' kubeadm kubelet kubectl cri-tools kubernetes-cni" </dev/null > "$new/$n.packages"
  done
  nx k8s-gw "systemctl stop $GW_STATEFUL 2>/dev/null; tar -czf - --ignore-failed-read $(echo "$GW_PATHS" | tr '\n' ' ') 2>/dev/null; rc=\$?
    systemctl start $GW_STATEFUL 2>/dev/null; exit \$rc" </dev/null > "$new/k8s-gw.tgz"
  # OpenBao on its own (raft snapshot through the API): the fast reset for labs that only touch kv/policies/roles
  if [ -s "$BAO_DIR/root-token" ]; then
    bx operator raft snapshot save "$new/openbao.snap" >/dev/null 2>&1 || die "OpenBao raft snapshot failed"
  fi
  nx "$CP" "etcdctl $ETCD_FLAGS snapshot save /var/tmp/golden-etcd.db >/dev/null && etcdutl snapshot status /var/tmp/golden-etcd.db -w table >&2 && cat /var/tmp/golden-etcd.db && rm -f /var/tmp/golden-etcd.db" \
    </dev/null > "$new/etcd.db" 2> "$new/etcd.status"
  [ -s "$new/etcd.db" ] || die "etcd snapshot failed: $(cat "$new/etcd.status")"
  {
    echo "taken=$(date -u +%FT%TZ)"
    echo "kubernetes=$(kx version -o json | jq -r .serverVersion.gitVersion)"
    echo "nodes=$(cluster_nodes | tr '\n' ' ')"
  } > "$new/VERSION"
  rm -rf "$GOLDEN_DIR.prev"; [ -d "$GOLDEN_DIR" ] && mv "$GOLDEN_DIR" "$GOLDEN_DIR.prev"
  mv "$new" "$GOLDEN_DIR"
  ok "golden taken ($(du -sh "$GOLDEN_DIR" | cut -f1)): $(tr '\n' ' ' < "$GOLDEN_DIR/VERSION")"
}

# ----------------------------------------------------------------- reset ----
# reset_node_files <node>: kubelet stopped, runtime faults undone, golden files back, all pods removed
# (kubelet recreates what the API says), packages back to the golden versions if a scenario changed them
reset_node_files() {
  local n=$1
  [ -f "$GOLDEN_DIR/$n.tgz" ] || die "no golden for $n - ./lab cluster golden"
  push_file "$n" /var/tmp/k8slab-golden.tgz < "$GOLDEN_DIR/$n.tgz"
  push_file "$n" /var/tmp/k8slab-golden.packages < "$GOLDEN_DIR/$n.packages"
  nxi "$n" <<EOF
set -u
systemctl stop kubelet
pkill -CONT -x kubelet 2>/dev/null
# runtime faults (scenarios use these; see docs/FAULTS.md)
nft delete table inet lab_fault 2>/dev/null
for dev in enp0s3 enp0s8; do tc qdisc del dev \$dev root 2>/dev/null; done
systemctl set-property --runtime kubepods.slice CPUQuota= 2>/dev/null
rm -rf /etc/systemd/system/kubepods.slice.d /etc/systemd/system.control/kubepods.slice.d
swapoff -a; rm -f /swapfile
# golden files: managed directories are replaced as a whole
rm -rf /etc/kubernetes /etc/cni/net.d /etc/containerd /var/lib/kubelet/pki /etc/sysctl.d /etc/modules-load.d /etc/chrony \
  /usr/lib/systemd/system/kubelet.service.d /etc/systemd/system/kubelet.service.d
tar -xzf /var/tmp/k8slab-golden.tgz -C /
rm -f /var/tmp/k8slab-golden.tgz
modprobe overlay; modprobe br_netfilter
sysctl -q --system
systemctl daemon-reload
# enable too (L16 disables it); step at once and wait (bounded) for the sync - a clock days off breaks TLS
systemctl enable chrony >/dev/null 2>&1; systemctl restart chrony; chronyc -a makestep >/dev/null 2>&1
timeout 30 chronyc waitsync 25 1 0 1 >/dev/null 2>&1
# packages (a scenario may have up/downgraded them)
want=\$(tr '\n' ' ' < /var/tmp/k8slab-golden.packages)
have=\$(dpkg-query -W -f '\${Package}=\${Version} ' kubeadm kubelet kubectl cri-tools kubernetes-cni 2>/dev/null)
if [ "\$want" != "\$have" ]; then
  apt-get update -qq -o Dir::Etc::SourceList=sources.list.d/k8slab.list -o Dir::Etc::SourceParts=/dev/null -o APT::Get::List-Cleanup=0
  apt-mark unhold kubeadm kubelet kubectl >/dev/null
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --allow-downgrades --allow-change-held-packages \$want >/dev/null
  apt-mark hold kubeadm kubelet kubectl >/dev/null
fi
rm -f /var/tmp/k8slab-golden.packages
systemctl restart containerd
crictl rmp -af >/dev/null 2>&1
true
EOF
}

# reset_etcd: restore the golden etcd snapshot on the control plane (kubelet stopped, pods removed)
reset_etcd() {
  push_file "$CP" /var/tmp/golden-etcd.db < "$GOLDEN_DIR/etcd.db"
  nxi "$CP" <<EOF
set -eu
rm -rf /var/lib/etcd.restore
etcdutl snapshot restore /var/tmp/golden-etcd.db --data-dir /var/lib/etcd.restore --name $CP \
  --initial-cluster $CP=https://$(node_ip "$CP"):2380 --initial-advertise-peer-urls https://$(node_ip "$CP"):2380 \
  >/var/tmp/etcd-restore.log 2>&1 || { cat /var/tmp/etcd-restore.log >&2; exit 1; }
rm -rf /var/lib/etcd.before-reset
[ -d /var/lib/etcd ] && mv /var/lib/etcd /var/lib/etcd.before-reset
mv /var/lib/etcd.restore /var/lib/etcd
rm -f /var/tmp/golden-etcd.db
EOF
}

reset_gw() {
  push_file k8s-gw /var/tmp/k8slab-golden.tgz < "$GOLDEN_DIR/k8s-gw.tgz"
  nx k8s-gw "systemctl stop $GW_STATEFUL 2>/dev/null; rm -rf /var/lib/openbao/data /var/lib/gitea/data
    tar -xzf /var/tmp/k8slab-golden.tgz -C / && rm -f /var/tmp/k8slab-golden.tgz
    exportfs -ra; systemctl restart haproxy chrony nginx k8slab-registry k8slab-registry-auth nfs-server
    systemctl start $GW_STATEFUL 2>/dev/null; true" </dev/null
}

# reset_openbao: OpenBao back to the golden raft snapshot (kv, policies, auth roles, tokens) - seconds, no gw
# restart; the static seal and the root token are unchanged
reset_openbao() {
  [ -s "$GOLDEN_DIR/openbao.snap" ] || { warn "no OpenBao snapshot in the golden - ./lab cluster golden"; return 1; }
  # a scenario may have broken OpenBao itself (Y06: the seal key) - its config from the golden first
  if ! bao_unsealed; then
    openbao_config_restore
    retry 90 bao_unsealed || { warn "OpenBao still sealed or down after restoring /etc/openbao"; return 1; }
  fi
  bx operator raft snapshot restore "$GOLDEN_DIR/openbao.snap" >/dev/null 2>&1 \
    || bx operator raft snapshot restore -force "$GOLDEN_DIR/openbao.snap" >/dev/null 2>&1 \
    || { warn "OpenBao snapshot restore failed"; return 1; }
  retry 60 bao_unsealed || { warn "OpenBao sealed after the restore"; return 1; }
  retry 30 bx kv get -mount=secret shop || warn "OpenBao kv not readable after the restore"
}

# openbao_config_restore: /etc/openbao (config, TLS, seal key) back from the gw golden, then a restart
openbao_config_restore() {
  push_file k8s-gw /var/tmp/k8slab-golden.tgz < "$GOLDEN_DIR/k8s-gw.tgz"
  nx k8s-gw 'rm -rf /etc/openbao && tar -xzf /var/tmp/k8slab-golden.tgz -C / etc/openbao; rm -f /var/tmp/k8slab-golden.tgz
    systemctl reset-failed openbao 2>/dev/null; systemctl restart openbao' </dev/null
}

# root_app_reset: lab-apps is bootstrapped by hand (not in Git) - its spec back to bootstrap/root.yaml (D11)
root_app_reset() {
  local f="$LAB_DIR/infra/gitops/bootstrap/root.yaml" want
  want=$(kx apply -f "$f" --dry-run=client -o json | jq -cS .spec)
  [ "$(kx -n argocd get application lab-apps -o json 2>/dev/null | jq -cS .spec)" = "$want" ] && return 0
  kx -n argocd patch application lab-apps --type json -p "[{\"op\":\"replace\",\"path\":\"/spec\",\"value\":$want}]" >/dev/null 2>&1 \
    || kx apply -f "$f" >/dev/null
}

extra_apps() { kx -n argocd get applications.argoproj.io -o name 2>/dev/null | grep -vE '/(lab-apps|demo|shop)$'; }
no_extra_apps() { [ -z "$(extra_apps)" ]; }
unfinalize_app() { kx -n argocd patch "$1" --type merge -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1; }
# Argo CD logs "Unable to delete application resources: error getting app project" forever for an app whose
# AppProject is gone - strip its finalizer at once instead of waiting
unstick_apps() {
  local a p
  for a in $(extra_apps); do
    p=$(kx -n argocd get "$a" -o jsonpath='{.spec.project}' 2>/dev/null) || continue
    kx -n argocd get appprojects.argoproj.io "${p:-default}" >/dev/null 2>&1 || unfinalize_app "$a"
  done
  no_extra_apps
}

# reset_gitops_baseline: lab/gitops main back to the tag "baseline" (a normal force-push through Gitea, so its
# branch view stays right), then Argo CD re-reads it and re-syncs the apps
reset_gitops_baseline() {
  local w url a; w=$(mktemp -d)
  url="http://lab:$(cat "$GITEA_DIR/token")@192.168.56.20:3000/lab/gitops.git"
  if ! { git -C "$w" init -q && git -C "$w" fetch -q "$url" refs/tags/baseline \
         && git -C "$w" push -q --force "$url" FETCH_HEAD:refs/heads/main 2>/dev/null; }; then
    rm -rf "$w"; warn "gitops: main not reset"; return 1
  fi
  rm -rf "$w"
  # Argo CD's repo credentials (D05 rotates them) and the hand-bootstrapped root app (D11)
  argo_repo_secret || warn "gitops: repo-gitops not restored"
  root_app_reset || warn "gitops: lab-apps spec not restored"
  argo_refresh lab-apps; argo_sync lab-apps
  for a in demo shop; do argo_refresh "$a"; done
  # Applications / AppProjects that are not part of the baseline (created with kubectl, or left behind).
  # Apps first: an app whose AppProject is already gone can't run its resources finalizer and hangs in deletion,
  # which keeps lab-apps unhealthy. lab-apps' own prune deletes both at once (D04), so strip such an app's
  # finalizer - its resources live in the scenario's namespaces, which the reset deletes next.
  for a in $(extra_apps); do kx -n argocd delete "$a" --wait=false >/dev/null 2>&1; done
  if ! retry 60 unstick_apps; then
    for a in $(extra_apps); do unfinalize_app "$a"; done
    retry 30 no_extra_apps || warn "gitops: Applications still terminating: $(extra_apps | tr '\n' ' ')"
  fi
  for a in $(kx -n argocd get appprojects.argoproj.io -o name 2>/dev/null); do
    case ${a##*/} in lab|default) ;; *) kx -n argocd delete "$a" --wait=false >/dev/null 2>&1 ;; esac
  done
  retry 180 root_converged || warn "argo app lab-apps not Synced/Healthy after the GitOps reset"
  for a in demo shop; do retry 180 argo_app_ok "$a" || warn "argo app $a not Synced/Healthy after the GitOps reset"; done
}
# root_converged: lab-apps Synced + Healthy - its prune can race the deletion of extra apps ("applications ... not
# found", D08) and auto-sync never retries a failed revision, so a failed root sync is started again
root_converged() {
  argo_app_ok lab-apps && return 0
  [ "$(kx -n argocd get application lab-apps -o jsonpath='{.status.operationState.phase}' 2>/dev/null)" = Running ] || argo_sync lab-apps
  return 1
}

# enable too: a scenario may have disabled kubelet, which would bite at the next reboot
start_kubelets() { local n; for n in "$@"; do nx "$n" 'systemctl enable --now containerd kubelet 2>/dev/null' </dev/null; done; }

# cluster_bare_build <version>: a bare cluster (control plane + workers + Calico, no other addons) at an older
# version - the starting point of the upgrade labs (T09, K13). kubeadm reset everywhere, but cp1 keeps its PKI:
# kubeadm init reuses an existing CA and SA key, so the desktop kubeconfig (a client cert of that CA, group
# kubeadm:cluster-admins), OpenBao's kubernetes auth and the golden stay valid. Not the kubeconfigs: with an
# existing admin.conf, init tries to create its ClusterRoleBinding before the API is up, and fails.
# The next "cluster" reset brings back the golden (packages included).
cluster_bare_build() {
  local v=${1:-$K8S_BUILD_VERSION} n pids=()
  ensure_tools
  info "bare cluster at v$v: kubeadm reset on every node ($CP keeps its PKI)"
  nx "$CP" 'rm -rf /var/tmp/k8slab-pki && mkdir -p /var/tmp/k8slab-pki && cp -a /etc/kubernetes/pki /var/tmp/k8slab-pki/' </dev/null \
    || die "could not save the PKI on $CP"
  for n in $(cluster_nodes); do
    nxi "$n" > /dev/null 2>&1 <<'EOF2' & pids+=($!)
set -u
kubeadm reset -f
rm -rf /etc/cni/net.d/* /var/lib/etcd /etc/kubernetes/kubeadm /var/lib/calico /var/run/calico
ip link del vxlan.calico 2>/dev/null
iptables -F; iptables -t nat -F; iptables -t mangle -F; iptables -X; iptables -t nat -X; iptables -t mangle -X
ipvsadm --clear 2>/dev/null
true
EOF2
  done
  for n in "${pids[@]}"; do wait "$n" || true; done
  pids=()
  for n in $(cluster_nodes); do pkg_install "$n" "$v" kubeadm kubelet kubectl </dev/null & pids+=($!); done
  for n in "${pids[@]}"; do wait "$n" || die "package downgrade to $v failed"; done
  nx "$CP" 'mkdir -p /etc/kubernetes && cp -a /var/tmp/k8slab-pki/pki /etc/kubernetes/ && rm -rf /var/tmp/k8slab-pki' </dev/null
  info "kubeadm init on $CP (v$v, existing CA)"
  render "$LAB_DIR/infra/node/kubeadm-init.yaml.tpl" CP="$CP" CP_IP="$(node_ip "$CP")" VERSION="$v" \
    API_ENDPOINT="$API_ENDPOINT" POD_CIDR="$POD_CIDR" SERVICE_CIDR="$SERVICE_CIDR" \
    | push_file "$CP" /etc/kubernetes/kubeadm/init.yaml
  nx "$CP" 'kubeadm init --config /etc/kubernetes/kubeadm/init.yaml' </dev/null > "$STATE_DIR/kubeadm-init.log" 2>&1 \
    || { tail -20 "$STATE_DIR/kubeadm-init.log"; die "kubeadm init failed - $(rel "$STATE_DIR/kubeadm-init.log")"; }
  retry 120 kx get --raw /readyz || die "API not up after kubeadm init (the desktop kubeconfig should still be valid)"
  local -a ws; mapfile -t ws < <(workers)
  cluster_join "${ws[@]}"
  for n in $(cluster_nodes); do kx label node "$n" "topology.kubernetes.io/zone=$(zone_of "$n")" --overwrite >/dev/null; done
  approve_csrs
  addon_calico
  ok "bare cluster up: $(kx version -o json | jq -r .serverVersion.gitVersion), $(kx get nodes --no-headers | wc -l) nodes"
}

# cluster_reset [cluster | node <names...>]
cluster_reset() {
  local level=${1:-cluster} n t0=$SECONDS; [ $# -gt 0 ] && shift
  local -a nodes pids=()
  [ -f "$GOLDEN_DIR/VERSION" ] || die "no golden yet - ./lab cluster golden"
  ensure_tools
  case $level in
    node)
      [ $# -gt 0 ] || die "usage: ./lab cluster reset node <node...>"
      mapfile -t nodes < <(nodes_or_default "$@")
      info "reset node(s) ${nodes[*]} to the golden"
      for n in "${nodes[@]}"; do reset_node_files "$n" </dev/null & pids+=($!); done
      for n in "${pids[@]}"; do wait "$n" || die "node reset failed"; done
      start_kubelets "${nodes[@]}" ;;
    cluster)
      mapfile -t nodes < <(cluster_nodes)
      info "reset the whole cluster to the golden ($(grep -o 'kubernetes=[^ ]*' "$GOLDEN_DIR/VERSION"))"
      for n in "${nodes[@]}"; do reset_node_files "$n" </dev/null & pids+=($!); done
      reset_gw </dev/null & pids+=($!)
      for n in "${pids[@]}"; do wait "$n" || die "reset failed"; done
      reset_etcd </dev/null
      start_kubelets "$CP"
      retry 180 kx get --raw /readyz || die "API not back after the etcd restore"
      start_kubelets "${nodes[@]:1}" ;;
    *) die "usage: ./lab cluster reset [cluster | node <node...>]" ;;
  esac
  retry 240 nodes_ready || warn "not all nodes Ready yet"
  approve_pending_csrs
  ok "reset done in $((SECONDS - t0)) s"
  cluster_doctor
}

# cluster_rebuild: the last resort - kubeadm reset everywhere, then build, upgrade and a new golden
cluster_rebuild() {
  local n
  ensure_tools
  info "kubeadm reset on every node"
  for n in $(cluster_nodes); do
    nx "$n" 'kubeadm reset -f >/dev/null 2>&1; rm -rf /etc/cni/net.d/* /var/lib/etcd /etc/kubernetes/kubeadm
      iptables -F; iptables -t nat -F; iptables -t mangle -F; iptables -X; ipvsadm --clear 2>/dev/null; true' </dev/null
  done
  rm -f "$KUBECONFIG"
  cluster_build "$K8S_BUILD_VERSION"
  cluster_upgrade "$(minor_of "$K8S_VERSION")"
  if [ -s "$BAO_DIR/root-token" ]; then gitops_stack; gitops_seed; fi   # Phase 2 stack (sealing key restored from .state)
  cluster_golden
}
