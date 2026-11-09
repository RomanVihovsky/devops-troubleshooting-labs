#!/usr/bin/env bash
# provision.sh - runs ON k8s-gw as root (./lab vm provision gw). Idempotent.
# k8s-gw is the lab's "ops box": distro packages + static binaries under systemd, no container runtime.
#   :5000 registry (distribution)   :8080 nginx artifact server (apt repo + files)   :6443 haproxy -> cp1
#   NTP server (chrony)             NFS /srv/nfs
set -euo pipefail
SRC=/srv/k8slab/src
# shellcheck source=versions.env source-path=SCRIPTDIR/../..
source "$SRC/versions.env"
FILES=/srv/k8slab/files
export DEBIAN_FRONTEND=noninteractive
say() { echo "==> $*"; }

say "packages"
for _ in 1 2 3; do if apt-get update -qq; then break; fi; sleep 5; done
apt-get install -y -qq --no-install-recommends nginx haproxy chrony nfs-kernel-server dpkg-dev gnupg curl jq \
  ca-certificates >/dev/null
install -d /srv/k8slab/files /srv/k8slab/apt /srv/k8slab/registry /srv/k8slab/work /etc/k8slab

bash "$SRC/infra/gw/sync.sh" files

say "binaries: registry $REGISTRY_VERSION, crane $CRANE_VERSION, helm $HELM_VERSION"
t=$(mktemp -d)
tar -xzf "$FILES/registry_${REGISTRY_VERSION}_linux_amd64.tar.gz" -C "$t"
tar -xzf "$FILES/crane-$CRANE_VERSION-linux-amd64.tar.gz" -C "$t" crane
tar -xzf "$FILES/helm-v$HELM_VERSION-linux-amd64.tar.gz" -C "$t" linux-amd64/helm
install -m 755 "$(find "$t" -type f -name registry | head -1)" /usr/local/bin/registry
install -m 755 "$t/crane" /usr/local/bin/crane
install -m 755 "$t/linux-amd64/helm" /usr/local/bin/helm
rm -rf "$t"

say "registry :5000"
id k8slab-registry >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin k8slab-registry
chown -R k8slab-registry: /srv/k8slab/registry
install -m 644 "$SRC/infra/gw/registry.yml" /etc/k8slab/registry.yml
install -m 644 "$SRC/infra/gw/k8slab-registry.service" /etc/systemd/system/k8slab-registry.service
systemctl daemon-reload
systemctl enable --now k8slab-registry >/dev/null 2>&1
systemctl restart k8slab-registry

say "nginx :8080 (artifact server)"
install -m 644 "$SRC/infra/gw/nginx-k8slab.conf" /etc/nginx/sites-available/k8slab
ln -sf /etc/nginx/sites-available/k8slab /etc/nginx/sites-enabled/k8slab
rm -f /etc/nginx/sites-enabled/default
nginx -t -q
systemctl enable nginx >/dev/null 2>&1; systemctl restart nginx

say "haproxy :6443 -> k8s-cp1"
install -m 644 "$SRC/infra/gw/haproxy.cfg" /etc/haproxy/haproxy.cfg
haproxy -c -q -f /etc/haproxy/haproxy.cfg
systemctl enable haproxy >/dev/null 2>&1; systemctl restart haproxy

say "chrony (NTP server for 192.168.56.0/24)"
install -m 644 "$SRC/infra/gw/chrony.conf" /etc/chrony/conf.d/k8slab.conf
systemctl enable chrony >/dev/null 2>&1; systemctl restart chrony

say "NFS /srv/nfs"
install -d -m 0777 /srv/nfs
install -D -m 644 "$SRC/infra/gw/exports" /etc/exports.d/k8slab.exports
systemctl enable nfs-server >/dev/null 2>&1; systemctl restart nfs-server
exportfs -ra

for _ in $(seq 30); do curl -fs http://registry.lab:5000/v2/ >/dev/null && break; sleep 1; done
bash "$SRC/infra/gw/sync.sh" apt
bash "$SRC/infra/gw/sync.sh" images
say "k8s-gw provisioned"
