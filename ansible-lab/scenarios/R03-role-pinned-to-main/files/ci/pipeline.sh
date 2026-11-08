#!/bin/sh
# CI: fresh role install, then deploy
set -eu
ansible-galaxy role install -r requirements.yml --force
exec ansible-playbook site.yml "$@"
