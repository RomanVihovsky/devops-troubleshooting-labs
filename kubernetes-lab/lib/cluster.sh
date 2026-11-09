# shellcheck shell=bash disable=SC2029,SC2016,SC2153,SC2034
# The kubeadm cluster: build (init + join + addons), doctor. Runs on the desktop; nodes via lib/vm.sh
# (nssh/nx), the API through haproxy on k8s-gw (https://192.168.56.20:6443), files from k8s-gw:8080.
# SC2029/SC2016: remote commands built on purpose; SC2153/SC2034: names from versions.env / common.sh.

BIN_DIR="$CACHE_DIR/bin"
FILES_DIR="$CACHE_DIR/files"
export KUBECONFIG="$STATE_DIR/kubeconfig"
export PATH="$BIN_DIR:$PATH"
CP=k8s-cp1
ADDONS="$LAB_DIR/infra/addons"

kx() { kubectl "$@"; }
workers() { node_rows | awk '$7 == "worker" { print $1 }'; }
cluster_nodes() { node_rows | awk '$7 == "control-plane" || $7 == "worker" { print $1 }'; }
zone_of() { case $1 in k8s-w3) echo zone-b ;; *) echo zone-a ;; esac; }

# gw_file <name>: path of a pinned file in cache/files, fetched from k8s-gw and verified (infra/artifacts.txt)
gw_file() {
  local name=$1 sum f="$FILES_DIR/$1"
  sum=$(awk -v n="$name" '$1 == n { print $3 }' "$LAB_DIR/infra/artifacts.txt")
  [ -n "$sum" ] || die "$name is not in infra/artifacts.txt"
  if [ ! -f "$f" ] || ! echo "$sum  $f" | sha256sum -c --quiet - >/dev/null 2>&1; then
    mkdir -p "$FILES_DIR"; fetch "$GW_FILES/files/$name" "$f" "$sum" >&2 || die "cannot fetch $name from k8s-gw"
  fi
  echo "$f"
}
# desktop tools: kubectl (pinned, cached) and helm (from k8s-gw)
ensure_tools() {
  mkdir -p "$BIN_DIR"
  [ -x "$BIN_DIR/kubectl" ] || install -m 755 "$CACHE_DIR/kubectl" "$BIN_DIR/kubectl"
  if ! "$BIN_DIR/helm" version --short 2>/dev/null | grep -q "^v$HELM_VERSION"; then
    tar -xzf "$(gw_file "helm-v$HELM_VERSION-linux-amd64.tar.gz")" -C "$BIN_DIR" --strip-components=1 linux-amd64/helm
  fi
}
# render <template> key=value...: replace @KEY@ placeholders
render() {
  local f=$1 kv args=(); shift
  for kv in "$@"; do args+=(-e "s|@${kv%%=*}@|${kv#*=}|g"); done
  sed "${args[@]}" "$f"
}
push_file() { nssh "$1" "sudo -n install -D -m ${3:-600} /dev/stdin $2"; }   # stdin -> node:path

# ----------------------------------------------------------------- build ----
cluster_build() {
  local version=${1:-$K8S_BUILD_VERSION} n
  ensure_tools
  nssh "$CP" 'command -v kubeadm >/dev/null' </dev/null || die "nodes not provisioned yet: ./lab vm provision nodes"
  if nssh "$CP" 'test -f /etc/kubernetes/admin.conf' </dev/null; then
    die "$CP is already initialised - ./lab cluster rebuild starts over"
  fi
  info "kubeadm init on $CP (v$version)"
  render "$LAB_DIR/infra/node/kubeadm-init.yaml.tpl" CP="$CP" CP_IP="$(node_ip "$CP")" VERSION="$version" \
    API_ENDPOINT="$API_ENDPOINT" POD_CIDR="$POD_CIDR" SERVICE_CIDR="$SERVICE_CIDR" \
    | push_file "$CP" /etc/kubernetes/kubeadm/init.yaml
  nx "$CP" 'kubeadm init --config /etc/kubernetes/kubeadm/init.yaml' </dev/null > "$STATE_DIR/kubeadm-init.log" 2>&1 \
    || { tail -20 "$STATE_DIR/kubeadm-init.log"; die "kubeadm init failed - $(rel "$STATE_DIR/kubeadm-init.log")"; }
  fetch_kubeconfig
  ok "control plane up: $(kx version -o json | jq -r .serverVersion.gitVersion)"

  local -a ws; mapfile -t ws < <(workers)
  cluster_join "${ws[@]}"
  for n in $(cluster_nodes); do kx label node "$n" "topology.kubernetes.io/zone=$(zone_of "$n")" --overwrite >/dev/null; done
  approve_csrs          # before the addons: metrics-server only gets ready once kubelets have serving certs
  addons_install
  cluster_doctor
}

# kubeconfig for the desktop: admin.conf with the API at the haproxy IP (k8s-api.lab only resolves on the VMs)
fetch_kubeconfig() {
  nx "$CP" 'cat /etc/kubernetes/admin.conf' </dev/null \
    | sed "s|server: https://.*:6443|server: https://192.168.56.20:6443|" > "$KUBECONFIG.new"
  chmod 600 "$KUBECONFIG.new"; mv "$KUBECONFIG.new" "$KUBECONFIG"
}

# cluster_join <workers...>: kubeadm join in parallel with a fresh token
cluster_join() {
  local join token hash n pids=() failed=0
  [ $# -gt 0 ] || return 0
  join=$(nx "$CP" 'kubeadm token create --ttl 30m --print-join-command' </dev/null)
  token=$(awk '{ for (i = 1; i < NF; i++) if ($i == "--token") print $(i + 1) }' <<<"$join")
  hash=$(awk '{ for (i = 1; i < NF; i++) if ($i == "--discovery-token-ca-cert-hash") print $(i + 1) }' <<<"$join")
  if [ -z "$token" ] || [ -z "$hash" ]; then die "could not get a join token from $CP"; fi
  info "kubeadm join: $*"
  for n in "$@"; do
    (
      render "$LAB_DIR/infra/node/kubeadm-join.yaml.tpl" NODE="$n" NODE_IP="$(node_ip "$n")" \
        API_ENDPOINT="$API_ENDPOINT" TOKEN="$token" CA_HASH="$hash" | push_file "$n" /etc/kubernetes/kubeadm/join.yaml
      nx "$n" 'kubeadm join --config /etc/kubernetes/kubeadm/join.yaml' </dev/null > "$STATE_DIR/kubeadm-join-$n.log" 2>&1
    ) & pids+=($!)
  done
  for n in "${pids[@]}"; do wait "$n" || failed=1; done
  [ $failed = 0 ] || die "kubeadm join failed - see $(rel "$STATE_DIR")/kubeadm-join-*.log"
}

# kubelet serving certs (serverTLSBootstrap): approve the pending kubelet-serving CSRs until every node has one
approve_csrs() {
  local want pending _
  want=$(cluster_nodes | wc -l)
  for _ in $(seq 60); do
    pending=$(kx get csr -o json | jq -r '.items[] | select(.spec.signerName == "kubernetes.io/kubelet-serving")
      | select((.status.conditions // []) | length == 0) | .metadata.name')
    # shellcheck disable=SC2086
    [ -z "$pending" ] || kx certificate approve $pending >/dev/null
    [ "$(kx get csr -o json | jq '[.items[] | select(.spec.signerName == "kubernetes.io/kubelet-serving")
        | select(any(.status.conditions[]?; .type == "Approved")) | .spec.username] | unique | length')" -ge "$want" ] && return 0
    sleep 2
  done
  warn "not every node got an approved kubelet serving cert (kubectl get csr)"
}

# ---------------------------------------------------------------- addons ----
helm_up() {   # release namespace chart-file values-file
  helm upgrade --install "$1" "$3" -n "$2" --create-namespace -f "$4" --wait --timeout 6m >/dev/null
}
addons_install() {
  local f
  info "Calico $CALICO_VERSION (VXLAN)"
  f="$FILES_DIR/calico-lab.yaml"
  python3 -I "$ADDONS/calico-patch.py" "$(gw_file "calico-$CALICO_VERSION.yaml")" "$f" "$POD_CIDR" 192.168.56.0/24 >/dev/null
  kx apply --server-side --force-conflicts -f "$f" >/dev/null
  kx -n kube-system rollout status ds/calico-node --timeout=6m >/dev/null
  kx -n kube-system rollout status deploy/calico-kube-controllers --timeout=4m >/dev/null
  kx wait --for=condition=Ready nodes --all --timeout=4m >/dev/null

  info "Gateway API $GATEWAY_API_VERSION CRDs"
  kx apply --server-side --force-conflicts -f "$(gw_file "gateway-api-$GATEWAY_API_VERSION-standard.yaml")" >/dev/null

  info "MetalLB (L2, $METALLB_POOL)"
  helm_up metallb metallb-system "$(gw_file "metallb-$METALLB_CHART_VERSION.tgz")" "$ADDONS/metallb-values.yaml"
  retry 120 kx apply -f "$ADDONS/metallb-config.yaml" || die "MetalLB pool not accepted (webhook?)"

  info "Traefik (Ingress + Gateway API, LoadBalancer 192.168.56.200)"
  helm_up traefik traefik "$(gw_file "traefik-$TRAEFIK_CHART_VERSION.tgz")" "$ADDONS/traefik-values.yaml"

  info "metrics-server"
  helm_up metrics-server kube-system "$(gw_file "metrics-server-$METRICS_SERVER_CHART_VERSION.tgz")" "$ADDONS/metrics-server-values.yaml"

  info "storage: local-path (default), snapshot controller, csi-driver-nfs (StorageClass nfs, RWX)"
  sed "s|image: docker.io/library/busybox\$|image: $BUSYBOX_IMAGE|" "$(gw_file "local-path-$LOCAL_PATH_VERSION.yaml")" | kx apply -f - >/dev/null
  kx patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' >/dev/null
  for f in volumesnapshotclasses volumesnapshotcontents volumesnapshots; do
    kx apply --server-side -f "$(gw_file "snapshot-$SNAPSHOTTER_VERSION-crd-$f.yaml")" >/dev/null
  done
  kx apply -f "$(gw_file "snapshot-$SNAPSHOTTER_VERSION-rbac-snapshot-controller.yaml")" \
           -f "$(gw_file "snapshot-$SNAPSHOTTER_VERSION-setup-snapshot-controller.yaml")" >/dev/null
  helm_up csi-driver-nfs kube-system "$(gw_file "csi-driver-nfs-$CSI_NFS_CHART_VERSION.tgz")" "$ADDONS/nfs-values.yaml"
  kx apply -f "$ADDONS/storage.yaml" >/dev/null
  ok "addons installed"
}

# ---------------------------------------------------------------- doctor ----
nodes_ready() { ! kx get nodes --no-headers | awk '$2 != "Ready"' | grep -q .; }
nodes_count() { [ "$(kx get nodes --no-headers | wc -l)" -eq "$(cluster_nodes | wc -l)" ]; }
same_versions() {
  local srv; srv=$(kx version -o json | jq -r .serverVersion.gitVersion)
  ! kx get nodes -o jsonpath='{range .items[*]}{.status.nodeInfo.kubeletVersion}{"\n"}{end}' | grep -vxq "$srv"
}
system_pods_ok() {
  ! kx get pods -A --no-headers | awk '$4 != "Running" && $4 != "Completed"' | grep -q .
}
echo_pods() { kx -n lab-doctor get pods -l app=echo -o jsonpath='{range .items[*]}{.metadata.name} {.status.podIP} {.spec.nodeName}{"\n"}{end}'; }
pod_matrix() {   # every echo pod reaches every other echo pod (cross-node, through the Calico VXLAN)
  local src sip snode dst dip dnode bad=0
  while read -r src sip snode; do
    while read -r dst dip dnode; do
      [ "$src" = "$dst" ] && continue
      kx -n lab-doctor exec "$src" -- /agnhost connect --timeout 3s "$dip:8080" >/dev/null 2>&1 \
        || { echo "    $snode -> $dnode ($dip) failed" >&2; bad=1; }
    done < <(echo_pods)
  done < <(echo_pods)
  [ $bad = 0 ]
}
first_echo() { echo_pods | awk 'NR == 1 { print $1 }'; }
writer_pods() { kx -n lab-doctor get pods -l app=writer -o jsonpath='{range .items[*]}{.metadata.name} {.spec.nodeName}{"\n"}{end}'; }
rwx_shared() {   # each writer sees the file the other writer wrote from another node
  local a an b bn
  read -r a an b bn < <(writer_pods | tr '\n' ' ')
  [ -n "$b" ] && [ "$an" != "$bn" ] \
    && kx -n lab-doctor exec "$a" -- cat "/data/$bn" | grep -qx "$bn" \
    && kx -n lab-doctor exec "$b" -- cat "/data/$an" | grep -qx "$an"
}
snapshot_ready() { [ "$(kx -n lab-doctor get volumesnapshot shared -o jsonpath='{.status.readyToUse}')" = true ]; }
clocks_ok() {
  local n off
  for n in $(cluster_nodes) k8s-gw; do
    off=$(nssh "$n" "chronyc -n tracking | awk '/^System time/ { print \$4 }'" </dev/null) || return 1
    awk -v o="$off" 'BEGIN { exit !(o + 0 < 1.0) }' || { echo "    $n is $off s off" >&2; return 1; }
  done
}
cert_days() { nx "$CP" 'echo $(( ($(date -d "$(openssl x509 -enddate -noout -in /etc/kubernetes/pki/apiserver.crt | cut -d= -f2)" +%s) - $(date +%s)) / 86400 ))' </dev/null; }

# delete the doctor namespace and wait (bounded) until it is gone - a golden must not contain it
doctor_cleanup() {
  kx get namespace lab-doctor >/dev/null 2>&1 || return 0
  kx delete namespace lab-doctor --wait=false >/dev/null 2>&1
  kx wait --for=delete namespace/lab-doctor --timeout=120s >/dev/null 2>&1
}
cluster_doctor() {
  local np w
  ensure_tools
  CHECKS_FAILED=0
  echo "${C_BOLD}cluster doctor${C_0}"
  check "API answers through haproxy on k8s-gw (https://192.168.56.20:6443)" kx get --raw /readyz
  check "all $(cluster_nodes | wc -l) nodes registered" nodes_count
  check_eventually 120 "all nodes Ready" nodes_ready
  check "kubelets run the API server's version ($(kx version -o json 2>/dev/null | jq -r .serverVersion.gitVersion))" same_versions
  check_eventually 180 "all pods Running/Completed (kube-system, calico, metallb, traefik, ...)" system_pods_ok

  doctor_cleanup || warn "a previous lab-doctor namespace is still terminating"
  render "$ADDONS/doctor.yaml" AGNHOST="$AGNHOST_IMAGE" BUSYBOX="$BUSYBOX_IMAGE" | kx apply -f - >/dev/null
  check_eventually 180 "doctor workloads ready (agnhost on every node, 2 RWX writers)" \
    kx -n lab-doctor rollout status ds/echo deploy/writer --timeout=5s
  check "pod-to-pod across all nodes ($(echo_pods | wc -l) pods, Calico VXLAN)" pod_matrix
  check "Service DNS + ClusterIP (echo.lab-doctor:80 from a pod)" \
    kx -n lab-doctor exec "$(first_echo)" -- /agnhost connect --timeout 3s echo.lab-doctor.svc.cluster.local:80
  if [ -f "$STATE_DIR/offline" ]; then echo "  - external DNS skipped (vm offline)"
  else check "external DNS from a pod (CoreDNS -> upstream)" \
         kx -n lab-doctor exec deploy/writer -- nslookup -timeout=3 pkgs.k8s.io; fi
  for w in $(workers); do
    np="http://$(node_ip "$w"):30999/hostname"
    check "NodePort from the desktop ($np)" curl -fs --max-time 5 "$np"
  done
  check_eventually 60 "LoadBalancer 192.168.56.200 (MetalLB L2) + Ingress, from the desktop" \
    curl -fs --max-time 5 -H 'Host: doctor.lab' http://192.168.56.200/hostname
  check_eventually 60 "Gateway API HTTPRoute through Traefik, from the desktop" \
    curl -fs --max-time 5 -H 'Host: doctor-gw.lab' http://192.168.56.200/hostname
  check_eventually 60 "NFS RWX volume shared by pods on two nodes" rwx_shared
  printf 'apiVersion: snapshot.storage.k8s.io/v1\nkind: VolumeSnapshot\nmetadata: {name: shared, namespace: lab-doctor}\nspec: {volumeSnapshotClassName: nfs, source: {persistentVolumeClaimName: shared}}\n' \
    | kx apply -f - >/dev/null
  check_eventually 90 "VolumeSnapshot of the NFS volume ready" snapshot_ready
  check_eventually 120 "kubectl top nodes (metrics-server, verified kubelet certs)" kx top nodes
  check "node clocks within 1 s (chrony from k8s-gw)" clocks_ok
  check "API server cert valid > 300 days ($(cert_days) left)" test "$(cert_days)" -gt 300
  gitops_checks
  doctor_cleanup || warn "namespace lab-doctor still terminating"
  verdict
}

# ------------------------------------------------------------------- env ----
cluster_env() {
  echo "export KUBECONFIG=$KUBECONFIG"
  echo "export PATH=$BIN_DIR:\$PATH"
  echo "# kubectl $("$BIN_DIR"/kubectl version --client -o json 2>/dev/null | jq -r .clientVersion.gitVersion), helm v$HELM_VERSION - use: eval \"\$(./lab env)\""
}
