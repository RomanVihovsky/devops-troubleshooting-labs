d=stacks/inventory-db
repo="$REGISTRY_URL/platform/tf-module-pgbox.git"
ver_ge_201() {
  ci_init $d || return 1
  jq -r '.Modules[] | select(.Key == "db") | .Source' "$CI/$d/.terraform/modules/modules.json" |
    grep -qE 'ref=v(2\.0\.[1-9][0-9]*|2\.[1-9][0-9]*\.[0-9]+|[3-9]\.[0-9]+\.[0-9]+)$'
}
# the release must upgrade a v1 user by itself: apply v1 in a sandbox, switch to the used ref, plan
release_upgrades() {
  local ref sb="$CI/upgrade-test"
  ref=$(jq -r '.Modules[] | select(.Key == "db") | .Source' "$CI/$d/.terraform/modules/modules.json" | sed 's/.*ref=//')
  rm -rf "$sb" && mkdir -p "$sb"
  sed -e "s/?ref=[^\"]*/?ref=v1.0.0/" -e 's/"inventory"/"zzupgrade"/' "$CI/$d/main.tf" > "$sb/main.tf"
  sed -i '/^moved {/,/^}/d' "$sb/main.tf"           # the module must do it, not the caller
  terraform -chdir="$sb" init -input=false -no-color >> "$VERIFY_LOG" 2>&1 &&
    terraform -chdir="$sb" apply -auto-approve -input=false -no-color >> "$VERIFY_LOG" 2>&1 || return 1
  sed -i "s/?ref=v1.0.0/?ref=$ref/" "$sb/main.tf"
  # moves alone are fine (exit code 2 counts them as changes) - nothing may be created/updated/destroyed
  local n=1
  if terraform -chdir="$sb" init -upgrade -input=false -no-color >> "$VERIFY_LOG" 2>&1 &&
     terraform -chdir="$sb" plan -input=false -no-color -out=up.tfplan >> "$VERIFY_LOG" 2>&1; then
    n=$(terraform -chdir="$sb" show -json up.tfplan | jq '[.resource_changes[] | select(.mode == "managed") | .change.actions | select(. != ["no-op"])] | length')
  fi
  terraform -chdir="$sb" destroy -auto-approve -input=false -no-color >> "$VERIFY_LOG" 2>&1 || true
  [ "$n" = 0 ]
}
originals() { same_ctr tfl-inventory-db && [ "$(docker volume inspect -f '{{.CreatedAt}}' tfl-inventory-pgdata 2>/dev/null)" = "$(recall vol)" ]; }
check "inventory uses tf-module-pgbox >= v2.0.1" ver_ge_201
check "that release upgrades a v1 user with no changes (moved blocks in the module)" release_upgrades
check "volume and container are the originals" originals
check "CI plan of stacks/inventory-db shows no changes" plan_clean $d
verdict
