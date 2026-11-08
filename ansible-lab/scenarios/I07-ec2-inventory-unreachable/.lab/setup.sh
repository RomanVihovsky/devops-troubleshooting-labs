aws_up
aws launch shop-web-1 web1 web >> "$SETUP_LOG"
aws launch shop-web-2 web2 web >> "$SETUP_LOG"
aws launch shop-db-1 db1 db >> "$SETUP_LOG"
# the CMDB era: a static export
H="$STATE_DIR/i07-history"; rm -rf "$H"; mkdir -p "$H"; mv inventory/prod.aws_ec2.yml "$H/"
cat > inventory/hosts.yml <<'YML'
# CMDB export 2026-09-30
all:
  children:
    web:
      hosts:
        shop-web-1:
          ansible_host: 10.78.0.11
        shop-web-2:
          ansible_host: 10.78.0.12
    db:
      hosts:
        shop-db-1:
          ansible_host: 10.78.0.21
YML
sed -i 's|^inventory = .*|inventory = inventory/hosts.yml|' ansible.cfg
ap site.yml
ws_commit "shop: web + db tiers (inventory: CMDB export)"
# this morning: the platform team's switch
git -C "$WS" rm -q inventory/hosts.yml
mkdir -p inventory; mv "$H/prod.aws_ec2.yml" inventory/; rm -rf "$H"
sed -i 's|^inventory = .*|inventory = inventory/prod.aws_ec2.yml|' ansible.cfg
ws_commit "inventory: EC2 dynamic inventory - the CMDB export is retired" "Platform Team"
echo "+ ansible-playbook site.yml   (this morning's deploy)" >> "$SETUP_LOG"
if ctl "ansible-playbook site.yml" >> "$SETUP_LOG" 2>&1; then die "the deploy worked in setup - fault not in place"; fi
