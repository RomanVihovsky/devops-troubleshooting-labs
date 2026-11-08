# Solution - L09

Reference: `.lab/solve.sh`.

**Takeaways**
* Inventory directories merge sources in name order; `constructed` builds groups from variables of hosts
  already loaded (so it comes *after* the source - `02-...`).
* `keyed_groups` -> one group per value; `groups` -> boolean expressions; `compose` -> new host vars.
  `strict: true` turns template errors into failures instead of silently skipping hosts.
* The same idea works with dynamic sources (`amazon.aws.aws_ec2`, `community.vmware...`, NetBox) - the
  playbooks only ever see groups.
* Patterns: `a:b` union, `a:&b` intersection, `a:!b` difference; `--limit` narrows further; `--list-hosts`
  before every scary run.
