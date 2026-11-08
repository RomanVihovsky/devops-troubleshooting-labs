#!/usr/bin/env bash
# CI deploy job (runner: shared docker executor). usage: CI_JOB_ID=<n> ci/deploy.sh
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
build=/tmp/ci-build-${CI_JOB_ID:?}

rm -rf "$build" && mkdir -p "$build"
cp -a "$src/." "$build/"
# 2026-10: the runner user differs from the checkout user -> make it writable for everyone (RUN-112)
chmod -R 0777 "$build"

cd "$build"
ansible-playbook site.yml -e "deploy_id=$CI_JOB_ID"
