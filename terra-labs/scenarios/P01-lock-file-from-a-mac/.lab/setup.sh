apply stacks/config-bundle
git add -f stacks/config-bundle/terraform.tfstate >/dev/null 2>&1 || true
ws_commit "config-bundle: manifest"
rm -f stacks/config-bundle/.terraform.lock.hcl
run_logged "$SETUP_LOG" tf stacks/config-bundle providers lock -fs-mirror="$TERRALAB_PROVIDER_MIRROR" -platform=darwin_arm64
rm -rf stacks/config-bundle/.terraform
ws_commit "lock providers" "Dev on a MacBook"
