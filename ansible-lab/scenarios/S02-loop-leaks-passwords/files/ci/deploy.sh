#!/bin/sh
# CI deploy (verbose logs are kept 90 days and visible to all engineers)
exec ansible-playbook site.yml -v "$@"
