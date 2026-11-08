#!/bin/bash
# Runs inside the Rocky node image (with internet) - fills /mirror/rocky9 with .rpms + repodata.
set -euo pipefail
rm -f /etc/yum.repos.d/acme.repo
cp /root/repos.orig/*.repo /etc/yum.repos.d/
# shellcheck disable=SC2086
for i in 1 2 3; do dnf -q -y download --resolve --destdir /mirror/rocky9 $PKGS && break || sleep 5; done
createrepo_c -q /mirror/rocky9
echo "rocky9: $(ls /mirror/rocky9/*.rpm | wc -l) packages, $(du -sh /mirror/rocky9 | cut -f1)"
