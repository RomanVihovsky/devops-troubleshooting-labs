#!/bin/sh
# PR pipeline: dry run with diff
exec ansible-playbook site.yml --check --diff "$@"
