cp deploy.yml "$STATE_DIR/e07-deploy.yml"
# before OPS-3011: the default (linear) strategy - correct, but every task waits for the slowest node
sed -i '/OPS-3011/d; /strategy: free/d' deploy.yml
ap deploy.yml
ws_commit "shop cluster deploy" "Platform Team"
cp "$STATE_DIR/e07-deploy.yml" deploy.yml; rm -f "$STATE_DIR/e07-deploy.yml"
ws_commit "deploy: strategy free - nobody waits for the slowest node (OPS-3011)" "Platform Team"
echo "+ ansible-playbook deploy.yml   (since OPS-3011)" >> "$SETUP_LOG"
if ctl "ansible-playbook deploy.yml" >> "$SETUP_LOG" 2>&1; then die "the free deploy worked in setup - fault not in place"; fi
