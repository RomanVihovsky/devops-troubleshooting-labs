## Hint 1
"Unable to parse inventory/ec2.yml as an inventory source": the `auto` plugin read `plugin:`, but
`aws_ec2`'s `verify_file()` only accepts names ending in `aws_ec2.yml` / `aws_ec2.yaml`. `git mv` it, then
`ansible-inventory --graph` (no `-i`) once `ansible.cfg` says `inventory = inventory/prod.aws_ec2.yml`.

## Hint 2
```yaml
regions:
  - eu-west-1
filters:
  tag:Env: prod
  instance-state-name: running
```
`ansible-inventory --host shop-web-9` would show it is stopped; `stg-web-1` has `Env=staging`.

## Hint 3
```yaml
keyed_groups:
  - key: ec2_tags.Role
    prefix: ""
    separator: ""
```
With an empty prefix the default separator `_` is still prepended (`_web`); `separator: ""` (or
`leading_separator: false`) gives `web`. The plugin adds the deprecated `tags` hostvar to every host until you set
`use_deprecated_tags: false` - that silences the deprecation and the 2.22 "reserved name 'tags'" warning.
