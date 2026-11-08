#!/usr/bin/env bash
# CI job "collection-sanity". ansible-test needs the collection under .../ansible_collections/<namespace>/<name>.
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
dest=/tmp/ci-sanity/ansible_collections/acme/ops
rm -rf "$dest"; mkdir -p "$dest"
tar -C "$src" --exclude=./.git --exclude=./.ansible --exclude=./tests/output -cf - . | tar -C "$dest" -xf -
cd "$dest"
ansible-test sanity --python 3.13 --color no "$@"
