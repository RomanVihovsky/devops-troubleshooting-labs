# history: web tier first, then the self-healing (v1 era), then the Monitoring 2.0 samples
H="$STATE_DIR/d01-history"; rm -rf "$H"; mkdir -p "$H"
mv docs/alerts/v2-nginx-critical.json docs/alerts/v2-nginx-ok.json docs/alerts/README.md rulebooks remediate "$H/"
ap site.yml
ws_commit "web tier: nginx + shop page" "Sam (SRE)"
mv "$H/rulebooks" "$H/remediate" .
ws_commit "EDA: self-healing for nginx (activation web-selfheal)" "Sam (SRE)"
eda_up rulebooks/web.yml
# last month: v1 alerts healed web1
nx web1 "systemctl stop nginx"
eda_post "$(cat docs/alerts/v1-nginx-down.json)"
retry 60 svc_active web1 nginx || die "v1 self-healing did not work in setup"
# Tuesday: Monitoring 2.0 - the samples land in the repo, the alerts change shape
mv "$H"/v2-nginx-critical.json "$H"/v2-nginx-ok.json "$H"/README.md docs/alerts/
ws_commit "docs: Monitoring 2.0 payload samples" "Monitoring Team"
rm -rf "$H"
nx web3 "systemctl stop nginx"
eda_post "$(cat docs/alerts/v2-nginx-critical.json)"
sleep 5
if svc_active web3 nginx; then die "a v2 alert healed web3 in setup - the fault is not in place"; fi
