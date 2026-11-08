#!/usr/bin/env bash
# CI job "deploy-prod" - runs on the shared runner (its /var/tmp survives between jobs)
set -euo pipefail
cd "$(dirname "$0")/.."
ansible-playbook site.yml "$@"
