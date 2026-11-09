# shellcheck shell=bash disable=SC2029,SC2016
# cluster_upgrade <minor|version> - the kubeadm upgrade procedure, scripted ("Upgrading kubeadm clusters"):
#   control plane: kubeadm (new) -> upgrade plan/apply -> drain -> kubelet+kubectl -> uncordon
#   each worker:   kubeadm (new) -> upgrade node -> drain -> kubelet+kubectl -> uncordon
# Packages come from the gw apt repo (both minors are there), so this works offline. It is also the
# reference solution of the upgrade scenario (K13 / learn lab T09).

minor_of() { echo "${1%.*}"; }

# pkg_install <node> <version> <pkg...>: install pinned k8s packages from the gw repo, keep them held
pkg_install() {
  local n=$1 v=$2; shift 2
  nxi "$n" <<EOF
set -eu
apt-get update -qq -o Dir::Etc::SourceList=sources.list.d/k8slab.list -o Dir::Etc::SourceParts=/dev/null -o APT::Get::List-Cleanup=0
kver=\$(apt-cache madison kubeadm | awk -v v="$v-" '!f && index(\$3, v) == 1 { print \$3; f = 1 }')
[ -n "\$kver" ] || { echo "kubeadm $v is not in the gw apt repo" >&2; exit 1; }
pkgs=""; for p in $*; do pkgs="\$pkgs \$p=\$kver"; done
apt-mark unhold $* >/dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --allow-downgrades --allow-change-held-packages \$pkgs >/dev/null
apt-mark hold $* >/dev/null
EOF
}
node_version() { kx get node "$1" -o jsonpath='{.status.nodeInfo.kubeletVersion}'; }
node_ready() { [ "$(kx get node "$1" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }

# upgrade_kubelet <node> <version>: drain, new kubelet + kubectl, restart, uncordon, wait Ready
upgrade_kubelet() {
  local n=$1 v=$2
  kx drain "$n" --ignore-daemonsets --delete-emptydir-data --timeout=5m >/dev/null
  pkg_install "$n" "$v" kubelet kubectl
  nx "$n" 'systemctl daemon-reload && systemctl restart kubelet' </dev/null
  # on the control plane the new kubelet recreates the static pods: the API is away (or still loading its
  # RBAC caches, answering Forbidden) for a while - so retry instead of failing on the first error
  retry 240 kx uncordon "$n" || die "could not uncordon $n"
  retry 180 node_ready "$n" || die "$n not Ready after the kubelet upgrade"
  [ "$(node_version "$n")" = "v$v" ] || die "$n reports $(node_version "$n"), expected v$v"
  ok "$n: v$v"
}

cluster_upgrade() {
  local target=${1:-} v w
  case $target in
    [0-9]*.[0-9]*.[0-9]*) v=$target ;;
    [0-9]*.[0-9]*) [ "$(minor_of "$K8S_VERSION")" = "$target" ] || die "no pinned $target.x (versions.env K8S_VERSION=$K8S_VERSION)"
                   v=$K8S_VERSION ;;
    *) die "usage: ./lab cluster upgrade <minor|version>   e.g. ./lab cluster upgrade $(minor_of "$K8S_VERSION")" ;;
  esac
  ensure_tools
  # idempotent: steps already done are skipped, so a rerun continues where an interrupted upgrade stopped
  if [ "$(kx version -o json | jq -r .serverVersion.gitVersion)" != "v$v" ]; then
    info "upgrade to v$v: $CP first (kubeadm upgrade apply)"
    pkg_install "$CP" "$v" kubeadm
    nx "$CP" "kubeadm upgrade plan v$v >/dev/null && kubeadm upgrade apply -y v$v" </dev/null > "$STATE_DIR/kubeadm-upgrade.log" 2>&1 \
      || { tail -15 "$STATE_DIR/kubeadm-upgrade.log"; die "kubeadm upgrade apply failed - $(rel "$STATE_DIR/kubeadm-upgrade.log")"; }
    retry 120 kx get --raw /readyz || die "API not back after the upgrade"
  else
    info "control plane already at v$v"
  fi
  if [ "$(node_version "$CP")" != "v$v" ]; then upgrade_kubelet "$CP" "$v"; else kx uncordon "$CP" >/dev/null; fi
  for w in $(workers); do
    if [ "$(node_version "$w")" = "v$v" ]; then kx uncordon "$w" >/dev/null; ok "$w: already v$v"; continue; fi
    info "$w: kubeadm upgrade node"
    pkg_install "$w" "$v" kubeadm
    nx "$w" 'kubeadm upgrade node' </dev/null >> "$STATE_DIR/kubeadm-upgrade.log" 2>&1 || die "kubeadm upgrade node failed on $w"
    upgrade_kubelet "$w" "$v"
  done
  ok "cluster upgraded to $(kx version -o json | jq -r .serverVersion.gitVersion)"
}
