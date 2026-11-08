#!/usr/bin/env bash
# CI job "collection-smoke": install the collection from this checkout, run the module against web1
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
dest=/tmp/ci-smoke/ansible_collections/acme/ops
rm -rf "$dest"; mkdir -p "$dest"
tar -C "$src" --exclude=./.git --exclude=./.ansible -cf - . | tar -C "$dest" -xf -
cd "$src"
ANSIBLE_COLLECTIONS_PATH=/tmp/ci-smoke:/usr/share/ansible/collections ansible-playbook playbooks/smoke.yml "$@"
