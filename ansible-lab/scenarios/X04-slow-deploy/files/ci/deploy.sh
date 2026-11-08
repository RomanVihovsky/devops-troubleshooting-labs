#!/bin/sh
# CI deploy with timing
set -eu
start=$(date +%s)
ansible-playbook site.yml "$@"
echo "deploy took $(( $(date +%s) - start ))s"
