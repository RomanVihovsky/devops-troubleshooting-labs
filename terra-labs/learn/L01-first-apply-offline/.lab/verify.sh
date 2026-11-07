pet=$(jq -r '.resources[] | select(.type == "random_pet") | .instances[0].attributes.id' \
  "$WS/hello/terraform.tfstate" 2>/dev/null || true)
greets_pet() { [ -n "$pet" ] && grep -qx "Hello, $pet!" "$WS/hello/out/greeting.txt"; }
pinned()     { [ "$(cat "$CI"/hello/*.tf | grep -cE 'version *= *"~>')" -ge 2 ]; }
lock_committed() {
  git -C "$WS" ls-files --error-unmatch hello/.terraform.lock.hcl >/dev/null 2>&1 &&
    git -C "$WS" diff --quiet HEAD -- hello/.terraform.lock.hcl
}
check "random and local pinned with ~>" pinned
check "state has random_pet.name" in_state hello random_pet.name
check "state has local_file.greeting" in_state hello local_file.greeting
check "out/greeting.txt says Hello, <the pet in state>!" greets_pet
check "lock file committed" lock_committed
check "CI plan of hello/ shows no changes" plan_clean hello
verdict
