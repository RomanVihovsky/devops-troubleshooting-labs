run_logged "$SETUP_LOG" tf stacks/config-bundle providers lock -fs-mirror="$TERRALAB_PROVIDER_MIRROR" \
  -platform=linux_amd64 -platform=darwin_arm64
git add stacks/config-bundle/.terraform.lock.hcl
git commit -q -m "lock providers for linux_amd64 + darwin_arm64"
