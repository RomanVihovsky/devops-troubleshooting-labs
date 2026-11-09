#!/usr/bin/env bash
# sync.sh files|apt|images|all - runs ON k8s-gw (as root). The only step that needs the internet: fills
#   /srv/k8slab/files     every file in infra/artifacts.txt, sha256-verified (+ SHA256SUMS for the nodes)
#   /srv/k8slab/apt       a flat apt repo with the pinned kubeadm/kubelet/kubectl/cri-tools/kubernetes-cni debs
#                         of BOTH Kubernetes minors (upgrade + rebuild work offline)
#   registry.lab:5000     every image the cluster uses, stored under its upstream host
#                         (registry.lab:5000/<host>/<path>:<tag>); the list goes to /srv/k8slab/images.txt
# Idempotent: what is already there and verified is skipped.
set -euo pipefail
SRC=/srv/k8slab/src
# shellcheck source=versions.env source-path=SCRIPTDIR/../..
source "$SRC/versions.env"
FILES=/srv/k8slab/files APT=/srv/k8slab/apt WORK=/srv/k8slab/work REG=registry.lab:5000
say() { echo "==> $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }
minor() { echo "${1%.*}"; }

sync_files() {
  local name url sum f n=0
  mkdir -p "$FILES"
  while read -r name url sum; do
    case $name in ''|\#*) continue ;; esac
    f=$FILES/$name; n=$((n + 1))
    if [ -f "$f" ] && echo "$sum  $f" | sha256sum -c --quiet - 2>/dev/null; then continue; fi
    say "file $name"
    curl -fsSL --retry 3 --retry-delay 3 -o "$f.part" "$url"
    echo "$sum  $f.part" | sha256sum -c --quiet - || { rm -f "$f.part"; die "checksum mismatch: $name"; }
    mv "$f.part" "$f"
  done < "$SRC/infra/artifacts.txt"
  awk '!/^#/ && NF == 3 { print $3 "  " $1 }' "$SRC/infra/artifacts.txt" > "$FILES/SHA256SUMS"
  say "files: $n verified in $FILES"
}

# k8s_apt / k8s_aptc <minor> <args...>: apt-get / apt-cache against pkgs.k8s.io for one minor, private state
k8s_apt_opts() {
  local d="$WORK/apt-$1"
  echo "-o Dir::Etc::SourceList=$d/k8s.list -o Dir::Etc::SourceParts=/dev/null -o Dir::State::Lists=$d/lists"
  echo "-o Dir::Cache=$d/cache -o Debug::NoLocking=1 -o APT::Sandbox::User=root"
}
# shellcheck disable=SC2046  # the options are word-split on purpose (paths have no spaces)
k8s_apt()  { local m=$1; shift; apt-get -q $(k8s_apt_opts "$m") "$@"; }
# shellcheck disable=SC2046
k8s_aptc() { local m=$1; shift; apt-cache $(k8s_apt_opts "$m") "$@"; }
sync_apt() {
  local v m d kver tools cni
  mkdir -p "$APT"
  for v in "$K8S_BUILD_VERSION" "$K8S_VERSION"; do
    m=$(minor "$v"); d="$WORK/apt-$m"
    mkdir -p "$d/lists/partial" "$d/cache/archives/partial"
    if [ ! -s "$d/k8s.gpg" ]; then
      curl -fsSL "https://pkgs.k8s.io/core:/stable:/v$m/deb/Release.key" | gpg --dearmor --yes -o "$d/k8s.gpg"
    fi
    echo "deb [signed-by=$d/k8s.gpg] https://pkgs.k8s.io/core:/stable:/v$m/deb/ /" > "$d/k8s.list"
    k8s_apt "$m" update >/dev/null
    kver=$(k8s_aptc "$m" madison kubeadm | awk -v v="$v-" '!f && index($3, v) == 1 { print $3; f = 1 }')
    [ -n "$kver" ] || die "kubeadm $v not found on pkgs.k8s.io v$m"
    tools=$(k8s_aptc "$m" madison cri-tools | awk 'NR == 1 { print $3 }')
    cni=$(k8s_aptc "$m" madison kubernetes-cni | awk 'NR == 1 { print $3 }')
    say "apt v$m: kubeadm/kubelet/kubectl $kver, cri-tools $tools, kubernetes-cni $cni"
    (cd "$APT" && k8s_apt "$m" download "kubeadm=$kver" "kubelet=$kver" "kubectl=$kver" \
      "cri-tools=$tools" "kubernetes-cni=$cni" >/dev/null)
  done
  (cd "$APT" && dpkg-scanpackages --multiversion . /dev/null 2>/dev/null > Packages && gzip -9kf Packages)
  say "apt: $(grep -c '^Package:' "$APT/Packages") packages in $APT"
}

# --------------------------------------------------------------- images ----
# qualify <ref>: add the registry host (docker.io) and library/ the way containerd does
qualify() {
  local r=$1 first=${1%%/*}
  if [[ $r != */* ]]; then echo "docker.io/library/$r"
  elif [[ $first == *.* || $first == *:* || $first == localhost ]]; then
    if [[ $first == docker.io && ${r#docker.io/} != */* ]]; then echo "docker.io/library/${r#docker.io/}"; else echo "$r"; fi
  else echo "docker.io/$r"; fi
}
manifest_images() { grep -hE '^\s*(- )?image:' "$@" | sed -E 's/^\s*(- )?image:\s*//; s/["'\'']//g' | sort -u; }
chart_images() {   # chart-tgz values-file
  local vals=()
  [ -f "$2" ] && vals=(-f "$2")
  helm template lab "$1" "${vals[@]}" --kube-version "$K8S_VERSION" | manifest_images /dev/stdin
}
kubeadm_images() {   # version
  local d="$WORK/kubeadm-$1" debs
  debs=("$APT"/kubeadm_"$1"-*_amd64.deb)
  [ -f "${debs[0]}" ] || die "no kubeadm $1 deb in $APT (run sync.sh apt first)"
  [ -x "$d/usr/bin/kubeadm" ] || dpkg-deb -x "${debs[0]}" "$d"
  "$d/usr/bin/kubeadm" config images list --kubernetes-version "v$1" 2>/dev/null
}
gen_images() {
  local out=/srv/k8slab/images.txt
  {
    echo "# generated on k8s-gw by sync.sh from versions.env + infra/artifacts.txt + infra/addons/*-values.yaml"
    echo "# group image (mirrored to $REG/<image>)"
    kubeadm_images "$K8S_BUILD_VERSION" | sed "s|^|k8s-$(minor "$K8S_BUILD_VERSION") |"
    kubeadm_images "$K8S_VERSION" | sed "s|^|k8s-$(minor "$K8S_VERSION") |"
    manifest_images "$FILES/calico-$CALICO_VERSION.yaml" | sed 's|^|calico |'
    manifest_images "$FILES/local-path-$LOCAL_PATH_VERSION.yaml" "$FILES"/snapshot-"$SNAPSHOTTER_VERSION"-*.yaml | sed 's|^|storage |'
    chart_images "$FILES/metallb-$METALLB_CHART_VERSION.tgz" "$SRC/infra/addons/metallb-values.yaml" | sed 's|^|metallb |'
    chart_images "$FILES/traefik-$TRAEFIK_CHART_VERSION.tgz" "$SRC/infra/addons/traefik-values.yaml" | sed 's|^|traefik |'
    chart_images "$FILES/metrics-server-$METRICS_SERVER_CHART_VERSION.tgz" "$SRC/infra/addons/metrics-server-values.yaml" | sed 's|^|metrics |'
    chart_images "$FILES/csi-driver-nfs-$CSI_NFS_CHART_VERSION.tgz" "$SRC/infra/addons/nfs-values.yaml" | sed 's|^|storage |'
    printf 'lab %s\n' "$AGNHOST_IMAGE" "$BUSYBOX_IMAGE"
  } | while read -r g img; do
    case $g in \#*) echo "$g $img"; continue ;; esac
    img=$(qualify "$img")
    # an image without tag or digest would mean "latest" - never mirrored (local-path's helper gets BUSYBOX_IMAGE)
    if [[ ${img##*/} != *:* && $img != *@sha256:* ]]; then echo "skip unpinned image $img" >&2; continue; fi
    echo "$g $img"
  done | awk '!seen[$2]++' > "$out"
  say "images: $(grep -vc '^#' "$out") in $out"
}
crane_copy() {   # src dst [flags]: quiet unless it fails (crane logs every blob)
  local log="$WORK/crane.log"
  crane copy --insecure "${@:3}" "$1" "$2" >"$log" 2>&1 || { tail -5 "$log" >&2; die "crane copy $1 failed"; }
}
sync_images() {
  local g img dst n=0 c=0
  gen_images
  while read -r g img; do
    case $g in ''|\#*) continue ;; esac
    n=$((n + 1)); dst="$REG/${img%@sha256:*}"
    if [[ $img == *@sha256:* ]]; then
      # pinned by digest: copy the whole index so the digest stays valid
      [[ ${dst##*/} == *:* ]] || dst="$dst:pinned"
      crane digest --insecure "$REG/$img" >/dev/null 2>&1 && continue
      say "image $img (all platforms)"; crane_copy "$img" "$dst"
    else
      crane digest --insecure "$dst" >/dev/null 2>&1 && continue
      say "image $img"; crane_copy "$img" "$dst" --platform linux/amd64
    fi
    c=$((c + 1))
  done < /srv/k8slab/images.txt
  say "images: $n in $REG ($c copied now)"
}

mkdir -p "$WORK"
case ${1:-all} in
  files) sync_files ;;
  apt) sync_apt ;;
  images) sync_images ;;
  all) sync_files; sync_apt; sync_images ;;
  *) die "usage: sync.sh files|apt|images|all" ;;
esac
