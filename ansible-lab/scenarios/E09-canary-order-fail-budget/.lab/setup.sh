cp deploy.yml "$STATE_DIR/e09-deploy.yml"
sed -i '/OPS-2950/d' deploy.yml
ap deploy.yml -e shop_release=4.2.0
ws_commit "shop: canary deploy" "Platform Team"
cp "$STATE_DIR/e09-deploy.yml" deploy.yml; rm -f "$STATE_DIR/e09-deploy.yml"
ws_commit "deploy: deterministic order in the logs (OPS-2950)" "Platform Team"
ap deploy.yml -e shop_release=4.2.0
# yesterday: 5.0.0, then the rollback
echo "+ ansible-playbook deploy.yml -e shop_release=5.0.0   (yesterday)" >> "$SETUP_LOG"
if ctl "ansible-playbook deploy.yml -e shop_release=5.0.0" >> "$SETUP_LOG" 2>&1; then die "5.0.0 deployed fine in setup"; fi
[ "$(nx app2 'readlink /opt/shop/current')" = /opt/shop/5.0.0 ] || die "5.0.0 did not reach app2 in setup"
ap deploy.yml -e shop_release=4.2.0
