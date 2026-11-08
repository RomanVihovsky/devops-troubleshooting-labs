git mv inventory/ec2.yml inventory/prod.aws_ec2.yml
git rm -q inventory/hosts.yml
sed -i 's|^inventory = .*|inventory = inventory/prod.aws_ec2.yml|' ansible.cfg
python3 - inventory/prod.aws_ec2.yml <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace("# TODO: regions, filters, keyed_groups\n", """regions:
  - eu-west-1
filters:
  tag:Env: prod
  instance-state-name: running
use_deprecated_tags: false     # ec2_tags only (amazon.aws 12: "tags" is deprecated, and a reserved name)
keyed_groups:
  # groups "web" / "db" from the Role tag (no prefix, no leading "_")
  - key: ec2_tags.Role
    prefix: ""
    separator: ""
""")
open(p, "w").write(s)
PY
ctl "ansible-inventory --graph" >> "$SETUP_LOG"
