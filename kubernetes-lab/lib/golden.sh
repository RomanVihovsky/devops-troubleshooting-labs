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
swapoff -a
# golden files: managed directories are replaced as a whole
rm -rf /etc/kubernetes /etc/cni/net.d /etc/containerd /var/lib/kubelet/pki /etc/sysctl.d /etc/modules-load.d /etc/chrony \
  /usr/lib/systemd/system/kubelet.service.d /etc/systemd/system/kubelet.service.d
tar -xzf /var/tmp/k8slab-golden.tgz -C /
rm -f /var/tmp/k8slab-golden.tgz
modprobe overlay; modprobe br_netfilter
sysctl -q --system
systemctl daemon-reload
systemctl restart chrony; chronyc -a makestep >/dev/null 2>&1
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
    exportfs -ra; systemctl restart haproxy chrony nginx k8slab-registry nfs-server
    systemctl start $GW_STATEFUL 2>/dev/null; true" </dev/null
}

# enable too: a scenario may have disabled kubelet, which would bite at the next reboot
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
  argo_refresh lab-apps; argo_sync lab-apps
  for a in demo shop; do argo_refresh "$a"; done
  for a in lab-apps demo shop; do retry 180 argo_app_ok "$a" || warn "argo app $a not Synced/Healthy after the GitOps reset"; done
}

start_kubelets() { local n; for n in "$@"; do nx "$n" 'systemctl enable --now containerd kubelet 2>/dev/null' </dev/null; done; }

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
