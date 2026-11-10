#!/usr/bin/env bash
# provision.sh - runs ON a Kubernetes node (k8s-cp1, k8s-w*) as root (./lab vm provision nodes). Idempotent.
# Everything Kubernetes comes from k8s-gw: files + flat apt repo from :8080, images through containerd's
# mirror config from registry.lab:5000. Only the Ubuntu packages in step 1 come from the Ubuntu mirror.
set -euo pipefail
SRC=/srv/k8slab/src
# shellcheck source=versions.env source-path=SCRIPTDIR/../..
source "$SRC/versions.env"
export DEBIAN_FRONTEND=noninteractive
ME=$(hostname)
ROLE=$(awk -F, -v n="$ME" '$1 == n { gsub(/\r/, ""); print $7 }' "$SRC/infra/vbox/nodes.csv")
T=/var/tmp/k8slab; mkdir -p "$T"
say() { echo "==> $ME: $*"; }
die() { echo "ERROR: $ME: $*" >&2; exit 1; }
[ -n "$ROLE" ] || die "not in nodes.csv"

say "Ubuntu packages"
for _ in 1 2 3; do if apt-get update -qq; then break; fi; sleep 5; done
apt-get install -y -qq --no-install-recommends conntrack socat ipset nfs-common jq chrony tcpdump curl \
  ca-certificates >/dev/null

say "kernel modules, sysctls, swap"
printf 'overlay\nbr_netfilter\n' > /etc/modules-load.d/k8s.conf
modprobe overlay; modprobe br_netfilter
cat > /etc/sysctl.d/90-k8s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl -q --system
swapoff -a
sed -i -E '/\sswap\s/ s/^([^#])/#\1/' /etc/fstab

# gwfile <name>: download a pinned file from k8s-gw and verify it against its SHA256SUMS
curl -fsSL -o "$T/SHA256SUMS" "$GW_FILES/files/SHA256SUMS"
gwfile() {
  curl -fsSL -o "$T/$1" "$GW_FILES/files/$1"
  (cd "$T" && grep -E "  $1\$" SHA256SUMS | sha256sum -c --quiet -) || die "checksum mismatch: $1"
}

say "containerd $CONTAINERD_VERSION, runc $RUNC_VERSION"
gwfile "containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz"
gwfile "containerd-$CONTAINERD_VERSION.service"
gwfile "runc-$RUNC_VERSION.amd64"
tar -xzf "$T/containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz" -C /usr/local
install -m 755 "$T/runc-$RUNC_VERSION.amd64" /usr/local/sbin/runc
install -D -m 644 "$T/containerd-$CONTAINERD_VERSION.service" /usr/local/lib/systemd/system/containerd.service
install -D -m 644 "$SRC/infra/node/containerd-config.toml" /etc/containerd/config.toml
for up in registry.k8s.io quay.io docker.io ghcr.io; do
  server=https://$up; [ "$up" = docker.io ] && server=https://registry-1.docker.io
  mkdir -p "/etc/containerd/certs.d/$up"
  sed -e "s|@UPSTREAM@|$up|g" -e "s|@SERVER@|$server|g" "$SRC/infra/node/hosts.toml.tpl" > "/etc/containerd/certs.d/$up/hosts.toml"
done
# the lab's own images (registry.lab:5000/lab/...) - plain HTTP, so containerd must not try HTTPS
mkdir -p /etc/containerd/certs.d/registry.lab:5000
cat > /etc/containerd/certs.d/registry.lab:5000/hosts.toml <<'EOF'
# the lab registry on k8s-gw is plain HTTP
server = "http://registry.lab:5000"

[host."http://registry.lab:5000"]
  capabilities = ["pull", "resolve"]
EOF
systemctl daemon-reload
systemctl enable containerd >/dev/null 2>&1
systemctl restart containerd
cat > /etc/crictl.yaml <<'EOF'
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 30
EOF

say "kubeadm, kubelet, kubectl $K8S_BUILD_VERSION from k8s-gw"
echo "deb [trusted=yes] $GW_FILES/apt ./" > /etc/apt/sources.list.d/k8slab.list
apt-get update -qq -o Dir::Etc::SourceList=sources.list.d/k8slab.list -o Dir::Etc::SourceParts=/dev/null \
  -o APT::Get::List-Cleanup=0
kver=$(apt-cache madison kubeadm | awk -v v="$K8S_BUILD_VERSION-" '!f && index($3, v) == 1 { print $3; f = 1 }')
[ -n "$kver" ] || die "kubeadm $K8S_BUILD_VERSION not in the gw apt repo"
# a node that already joined a cluster (kubelet.conf exists on every node; admin.conf only on the control
# plane) keeps its packages - re-provisioning must never up/downgrade a running cluster (./lab cluster upgrade)
if [ "$(dpkg-query -W -f '${Version}' kubeadm 2>/dev/null)" != "$kver" ] && [ -f /etc/kubernetes/kubelet.conf ]; then
  say "kubeadm already initialised at another version - leaving the packages alone (use ./lab cluster upgrade)"
else
  apt-mark unhold kubeadm kubelet kubectl >/dev/null 2>&1 || true
  apt-get install -y -qq --allow-downgrades --allow-change-held-packages \
    "kubeadm=$kver" "kubelet=$kver" "kubectl=$kver" cri-tools kubernetes-cni >/dev/null
  apt-mark hold kubeadm kubelet kubectl >/dev/null
fi
systemctl enable kubelet >/dev/null 2>&1

say "time from k8s-gw (chrony)"
sed -i -E 's/^(pool|server) /#\1 /; s/^makestep .*/makestep 1 -1/' /etc/chrony/chrony.conf  # step after a host sleep too
echo 'server 192.168.56.20 iburst' > /etc/chrony/conf.d/k8slab.conf
systemctl enable chrony >/dev/null 2>&1; systemctl restart chrony

if [ "$ROLE" = control-plane ]; then
  say "etcdctl/etcdutl $ETCD_TOOLS_VERSION"
  gwfile "etcd-v$ETCD_TOOLS_VERSION-linux-amd64.tar.gz"
  tar -xzf "$T/etcd-v$ETCD_TOOLS_VERSION-linux-amd64.tar.gz" -C "$T"
  install -m 755 "$T/etcd-v$ETCD_TOOLS_VERSION-linux-amd64/etcdctl" "$T/etcd-v$ETCD_TOOLS_VERSION-linux-amd64/etcdutl" /usr/local/bin/
fi

say "pre-pulling the control-plane images of both versions + Calico (through the gw mirror)"
curl -fsSL -o "$T/images.txt" "$GW_FILES/images.txt"
n=0
while read -r group img; do
  case $group in k8s-*|calico) ;; *) continue ;; esac
  crictl pull "$img" >/dev/null || die "pull failed: $img"
  n=$((n + 1))
done < "$T/images.txt"
rm -rf "$T"
say "done: containerd $(containerd --version | awk '{print $3}'), kubelet $(kubelet --version | awk '{print $2}'), $n images pre-pulled"
