ctl "rm -rf /var/tmp/ansible-inventory-cache"
aws_up
# last month: four web instances (shop-web-8 / -9 were real machines back then)
for i in 1 2; do aws launch "shop-web-$i" "web$i" web >> "$SETUP_LOG"; done
aws launch shop-web-8 10.78.0.18 web >> "$SETUP_LOG"
aws launch shop-web-9 10.78.0.19 web >> "$SETUP_LOG"
ap site.yml --limit shop-web-1,shop-web-2     # (8 and 9 were deployed by hand back then)
ws_commit "shop: EC2 dynamic inventory" "Platform Team"
# INC-889: DescribeInstances throttling during the big deploy -> cache the inventory on the runner
cat >> inventory/prod.aws_ec2.yml <<'YML'
# INC-889: DescribeInstances throttling during the big deploy - cache the inventory on the runner
cache: true
cache_plugin: ansible.builtin.jsonfile
cache_connection: /var/tmp/ansible-inventory-cache
cache_timeout: 0
YML
ws_commit "inventory: cache EC2 results on the runner (INC-889)" "Platform Team"
ctl "ansible-inventory --graph" >> "$SETUP_LOG" 2>&1      # the first job after that filled the cache
# Monday: shop-web-8 stopped for forensics; last week: shop-web-9 terminated; yesterday: scale-out shop-web-3
aws stop shop-web-8; aws terminate shop-web-9
aws launch shop-web-3 web3 web >> "$SETUP_LOG"
echo "+ ci/deploy.sh   (today's job)" >> "$SETUP_LOG"
if ctl "ci/deploy.sh" >> "$SETUP_LOG" 2>&1; then die "the deploy worked in setup - fault not in place"; fi
