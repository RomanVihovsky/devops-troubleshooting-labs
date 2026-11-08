# L16 · Cloud inventory - amazon.aws.aws_ec2 against a fake AWS
**Learn** · amazon.aws 12 `aws_ec2` inventory plugin: config file naming, `regions`, `filters`, `keyed_groups`, `compose`, `ec2_tags` · ~30 min

The CMDB export in `inventory/hosts.yml` is retired - new instances never show up in it. Build the inventory from
EC2 instead. The lab runs a fake AWS account (moto at `aws.acme.internal`); the runner's environment already
has `AWS_ENDPOINT_URL`, `AWS_ACCESS_KEY_ID`, ... (`env | grep AWS` in `./lab sh`). Each EC2 instance's private IP
is a real lab node. The platform team left a template: `inventory/ec2.yml`.

1. `ansible-inventory -i inventory/ec2.yml --graph` finds nothing. Read the warnings, then rename the file to
   what the plugin accepts (`*.aws_ec2.yml`): `inventory/prod.aws_ec2.yml`. Point `ansible.cfg` at it and delete
   the static `inventory/hosts.yml`.
2. Only **eu-west-1** (without `regions:` the plugin asks every region - try `time`), only **Env=prod**, only
   **running** instances (`filters:` take EC2 API filter names, e.g. `tag:Env`, `instance-state-name`).
3. `keyed_groups` from the instances' `Role` tag must produce the groups **`web`** and **`db`** exactly - `site.yml`
   and `group_vars/` use them. Watch for a leading `_`. Use `ec2_tags`: the `tags` hostvar is deprecated (and a
   reserved name in 2.22) - switch it off as the plugin documentation says (`ansible-doc -t inventory amazon.aws.aws_ec2`).
4. Explore: `ansible-inventory --graph`, `--host shop-web-1` (every EC2 attribute is a hostvar), then
   `ansible-playbook site.yml`.

**Test**: `ansible-inventory` (from ansible.cfg) lists exactly shop-web-1, shop-web-2 (`web`) and shop-db-1 (`db`) with
their private IPs as `ansible_host` and EC2 hostvars, without deprecation warnings; the static inventory is gone; an
instance launched during the test (shop-web-3) joins `web` and site.yml configures it; site.yml converges.
