python3 - inventory/prod.aws_ec2.yml <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("  tag:Env: prod\n", "  tag:Env: prod\n  instance-state-name: running\n")
s = re.sub(r"# INC-889.*", "# no inventory cache: the deploy job must see the fleet as it is right now\n", s, flags=re.S)
open(p, "w").write(s)
PY
ctl "rm -rf /var/tmp/ansible-inventory-cache"
ctl "ci/deploy.sh" >> "$SETUP_LOG"
