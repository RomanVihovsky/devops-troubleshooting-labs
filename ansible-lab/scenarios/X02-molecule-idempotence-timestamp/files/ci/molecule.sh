#!/bin/sh
# CI: role tests
set -eu
root=$(pwd)
cd roles/node_report
ANSIBLE_ROLES_PATH="$root/roles" exec molecule test
