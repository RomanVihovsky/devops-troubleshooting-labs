#!/bin/sh
# vault password from the CI secret store (env)
printf "%s\n" "${ACME_VAULT_PASSWORD:?not set}"
