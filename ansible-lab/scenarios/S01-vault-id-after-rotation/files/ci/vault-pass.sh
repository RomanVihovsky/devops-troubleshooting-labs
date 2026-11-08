#!/bin/sh
# vault password from the CI secret store
printf "%s\n" "${ACME_VAULT_DEFAULT:?not set}"
