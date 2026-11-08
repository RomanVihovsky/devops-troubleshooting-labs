#!/bin/sh
# PR pipeline: the output is posted as a PR comment
exec ansible-playbook site.yml --check --diff "$@"
