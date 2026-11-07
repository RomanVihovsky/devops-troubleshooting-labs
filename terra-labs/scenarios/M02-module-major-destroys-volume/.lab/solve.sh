tmp=$(mktemp -d)
git clone -q "$REGISTRY_URL/platform/tf-module-pgbox.git" "$tmp/pgbox"
cat >> "$tmp/pgbox/main.tf" <<'TF'

# v2.0.0 renamed the resources - tell every caller's state
moved {
  from = docker_volume.data
  to   = docker_volume.this
}

moved {
  from = docker_container.db
  to   = docker_container.this
}
TF
git -C "$tmp/pgbox" add -A
git -C "$tmp/pgbox" commit -q -m "fix: moved blocks for the v2 rename"
git -C "$tmp/pgbox" tag v2.0.1
git -C "$tmp/pgbox" push -q origin main --tags
rm -rf "$tmp"
sed -i 's/?ref=v2.0.0/?ref=v2.0.1/' stacks/inventory-db/main.tf
run_logged "$SETUP_LOG" tf stacks/inventory-db init -upgrade -input=false -no-color
run_logged "$SETUP_LOG" tf stacks/inventory-db apply -auto-approve -input=false -no-color
