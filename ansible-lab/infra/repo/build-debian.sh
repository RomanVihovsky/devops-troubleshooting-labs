#!/bin/bash
# Runs inside the Debian node image (with internet) - fills /mirror/debian with .debs + Packages index.
set -euo pipefail
cp /root/debian.sources.orig /etc/apt/sources.list.d/debian.sources
rm -f /etc/apt/sources.list.d/acme.list
for i in 1 2 3 4 5; do apt-get update -qq && break || sleep 5; done
cd /var/cache/apt/archives
# shellcheck disable=SC2086
for i in 1 2 3; do apt-get install -y -qq --download-only --no-install-recommends $PKGS && break || sleep 5; done
cp -n /var/cache/apt/archives/*.deb /mirror/debian/
# packages already in the image (apt-get download fetches them regardless)
# shellcheck disable=SC2086
[ -n "${EXPLICIT:-}" ] && (cd /mirror/debian && apt-get download -qq $EXPLICIT)
cd /mirror/debian && dpkg-scanpackages --multiversion . /dev/null > Packages 2>/dev/null && gzip -kf Packages
echo "debian: $(ls *.deb | wc -l) packages, $(du -sh . | cut -f1)"
