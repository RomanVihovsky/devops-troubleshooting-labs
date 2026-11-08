cp deploy.yml "$STATE_DIR/e08-deploy.yml"
python3 - deploy.yml <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = s.index("    - name: Drop nodes that left"); b = s.index("  handlers:")
open(p, "w").write(s[:a] + s[b:])
PY
ap site.yml
for n in web1 web2 web3; do run_logged "$SETUP_LOG" nx lb1 "lb-register add $n $n:8080"; done   # netops tickets
ws_commit "shop: lb1 + web tier (LB registrations via netops tickets)" "Platform Team"
cp "$STATE_DIR/e08-deploy.yml" deploy.yml; rm -f "$STATE_DIR/e08-deploy.yml"
ws_commit "deploy: register web nodes on lb1 ourselves (NET-77)" "Platform Team"
ap deploy.yml
# last night: lb1 rebuilt from the golden image -> empty registry; then the 06:00 and 06:30 deploys
nx lb1 "lb-register reset" >> "$SETUP_LOG"
ap deploy.yml
ap deploy.yml
remember lbsha "$(nx lb1 'sha256sum /usr/local/sbin/lb-register' | cut -d' ' -f1)"
n=$(nx lb1 "lb-register list" | wc -l)
[ "$n" -lt 3 ] || die "the race did not happen in setup ($n registered)"
