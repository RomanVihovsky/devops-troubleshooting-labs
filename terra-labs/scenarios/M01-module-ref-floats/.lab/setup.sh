publish tf-module-web-config v1.2.0 "$SCN/.lab/modules/v1.2.0" "release v1.2.0"
state_bucket
apply stacks/storefront
# two weeks later, on the module's main branch (no tag yet)
publish tf-module-web-config - "$SCN/.lab/modules/main-next" "feat: warn by default, tracing parameter"
remember v120 "$(git ls-remote "$REGISTRY_URL/platform/tf-module-web-config.git" refs/tags/v1.2.0 | cut -f1)"
