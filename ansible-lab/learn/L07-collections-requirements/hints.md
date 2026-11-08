## Hint 1
`ls /opt/collections/`. Tarball entries in requirements: `- name: /opt/collections/<file>.tar.gz` with
`type: file` (they still carry their version inside).

## Hint 2
`tar -xzOf /opt/collections/community-general-14.0.0.tar.gz MANIFEST.json | jq .collection_info.dependencies`
-> `community.library_inventory_filtering_v1` - its tarball is in `/opt/collections/` too.
Roles from git: `- name: acme.logrotate`, `src: https://git.acme.example/platform/ansible-role-logrotate.git`,
`scm: git`, `version: v1.0.0`. `git ls-remote --tags <url>` shows what exists.

## Hint 3
```yaml
collections:
  - name: /opt/collections/community-general-14.0.0.tar.gz
    type: file
  - name: /opt/collections/ansible-posix-2.2.2.tar.gz
    type: file
  - name: /opt/collections/community-library_inventory_filtering_v1-1.1.5.tar.gz
    type: file
roles:
  - name: acme.logrotate
    src: https://git.acme.example/platform/ansible-role-logrotate.git
    scm: git
    version: v1.0.0
```
