#!/usr/bin/env bash
# provision.sh - runs ON k8s-gw as root (./lab vm provision gw). Idempotent.
# k8s-gw is the lab's "ops box": distro packages + static binaries under systemd, no container runtime.
#   :5000 registry (distribution)   :5001 the same images, read-only, htpasswd (the "private registry")
#   :8080 nginx artifact server (apt repo + files)   :6443 haproxy -> cp1
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
  ca-certificates apache2-utils >/dev/null
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

say "registry :5001 (read-only, htpasswd user ci)"
install -m 644 "$SRC/infra/gw/registry-auth.yml" /etc/k8slab/registry-auth.yml
[ -s /etc/k8slab/registry-ci.password ] || openssl rand -hex 12 > /etc/k8slab/registry-ci.password
chmod 600 /etc/k8slab/registry-ci.password
htpasswd -Bbc /etc/k8slab/registry-auth.htpasswd ci "$(cat /etc/k8slab/registry-ci.password)" 2>/dev/null
chown root:k8slab-registry /etc/k8slab/registry-auth.htpasswd; chmod 640 /etc/k8slab/registry-auth.htpasswd
install -m 644 "$SRC/infra/gw/k8slab-registry-auth.service" /etc/systemd/system/k8slab-registry-auth.service
systemctl daemon-reload
systemctl enable --now k8slab-registry-auth >/dev/null 2>&1
systemctl restart k8slab-registry-auth

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
# step any offset > 1 s, not only in the first 3 updates: a host that slept leaves the paused VMs hours behind
sed -i -E 's/^makestep .*/makestep 1 -1/' /etc/chrony/chrony.conf
systemctl enable chrony >/dev/null 2>&1; systemctl restart chrony

say "NFS /srv/nfs"
install -d -m 0777 /srv/nfs
install -D -m 644 "$SRC/infra/gw/exports" /etc/exports.d/k8slab.exports
systemctl enable nfs-server >/dev/null 2>&1; systemctl restart nfs-server
exportfs -ra

say "OpenBao $OPENBAO_VERSION (:8200, static-key auto-unseal)"
if [ "$(dpkg-query -W -f '${Version}' openbao 2>/dev/null)" != "$OPENBAO_VERSION" ]; then
  # (its postinst generates a self-signed cert we don't use - noisy, so only shown on failure)
  dpkg -i "$FILES/openbao_${OPENBAO_VERSION}_linux_amd64.deb" >/var/tmp/openbao-install.log 2>&1 \
    || { cat /var/tmp/openbao-install.log >&2; exit 1; }
fi
install -d -o openbao -g openbao -m 750 /var/lib/openbao /var/lib/openbao/data
install -d -o root -g openbao -m 750 /etc/openbao /etc/openbao/tls
if [ ! -s /etc/openbao/unseal.key ]; then openssl rand -out /etc/openbao/unseal.key 32; fi
chown openbao:openbao /etc/openbao/unseal.key; chmod 600 /etc/openbao/unseal.key
install -m 640 -o root -g openbao "$SRC/infra/gw/openbao.hcl" /etc/openbao/openbao.hcl
systemctl enable openbao >/dev/null 2>&1
# the TLS cert comes from the lab CA on the desktop (./lab gitops gw); until it is there, openbao stays down
if [ -s /etc/openbao/tls/bao.crt ]; then systemctl reset-failed openbao 2>/dev/null; systemctl restart openbao; fi

say "Gitea $GITEA_VERSION (:3000)"
id git >/dev/null 2>&1 || useradd --system --home-dir /var/lib/gitea --shell /usr/sbin/nologin git
install -m 755 "$FILES/gitea-$GITEA_VERSION-linux-amd64" /usr/local/bin/gitea
install -d -o git -g git /var/lib/gitea /var/lib/gitea/custom /var/lib/gitea/data /var/lib/gitea/log
install -d -o root -g git -m 770 /etc/gitea
# keep the generated secrets across re-provisioning, re-render everything else from the template
secret() { [ -f /etc/gitea/app.ini ] || return 0; awk -F' *= *' -v k="$1" '!f && $1 == k { print $2; f = 1 }' /etc/gitea/app.ini; }
sk=$(secret SECRET_KEY); it=$(secret INTERNAL_TOKEN); jw=$(secret JWT_SECRET)
[ -n "$sk" ] || sk=$(gitea generate secret SECRET_KEY)
[ -n "$it" ] || it=$(gitea generate secret INTERNAL_TOKEN)
[ -n "$jw" ] || jw=$(gitea generate secret JWT_SECRET)
sed -e "s|@SECRET_KEY@|$sk|" -e "s|@INTERNAL_TOKEN@|$it|" -e "s|@JWT_SECRET@|$jw|" \
  "$SRC/infra/gw/gitea-app.ini.tpl" > /etc/gitea/app.ini
chown root:git /etc/gitea/app.ini; chmod 660 /etc/gitea/app.ini
install -m 644 "$SRC/infra/gw/k8slab-gitea.service" /etc/systemd/system/k8slab-gitea.service
systemctl daemon-reload
systemctl enable k8slab-gitea >/dev/null 2>&1; systemctl restart k8slab-gitea

for _ in $(seq 30); do curl -fs http://registry.lab:5000/v2/ >/dev/null && break; sleep 1; done
bash "$SRC/infra/gw/sync.sh" apt
bash "$SRC/infra/gw/sync.sh" images
say "k8s-gw provisioned"
