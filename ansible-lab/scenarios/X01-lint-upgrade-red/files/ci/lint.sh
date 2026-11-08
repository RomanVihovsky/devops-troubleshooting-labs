#!/bin/sh
# CI lint gate
set -eu
exec ansible-lint --nocolor "$@"
