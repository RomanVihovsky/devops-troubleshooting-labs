# Solution - a plugin config the plugin accepts, scoped by region/filters, groups from ec2_tags

```yaml
# inventory/prod.aws_ec2.yml   (ansible.cfg: inventory = inventory/prod.aws_ec2.yml; hosts.yml deleted)
plugin: amazon.aws.aws_ec2
hostnames: [tag:Name]
compose:
  ansible_host: private_ip_address
regions: [eu-west-1]
filters:
  tag:Env: prod
  instance-state-name: running
use_deprecated_tags: false
keyed_groups:
  - key: ec2_tags.Role
    prefix: ""
    separator: ""
```

**Why**
* Inventory plugins with config files only claim files with their suffix (`*.aws_ec2.yml`); otherwise `auto`
  can't verify the file, `yaml` can't parse it - "No inventory was parsed" and an empty run.
* Without `regions` the plugin calls DescribeInstances in every region (slow, and finds the forgotten
  us-east-1 instance). EC2 API `filters` are applied server-side; terminated instances are excluded by default,
  **stopped ones are not**.
* `keyed_groups` name = prefix + separator + value; an empty prefix still gets the separator (`_web`).
* amazon.aws 12 deprecates the `tags` hostvar for `ec2_tags` and adds it to every host (with a warning) until
  `use_deprecated_tags: false`; `tags` is also a play keyword, so 2.22 warns about a reserved variable name.

**Interview notes**
* Dynamic inventory = truth from the API: hostnames (`tag:Name`, `private-ip-address`, `dns-name`) and
  `ansible_host` are separate decisions - see I07. Caching speeds it up and goes stale - see I08.
* Credentials from the environment / instance profile / OIDC in CI, never in the inventory file.
* `constructed` features (`keyed_groups`, `groups`, `compose`) work in every inventory plugin (L09).
