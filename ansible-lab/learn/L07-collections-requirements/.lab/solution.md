# Solution - L07

```yaml
collections:
  - {name: /opt/collections/community-general-14.0.0.tar.gz, type: file}
  - {name: /opt/collections/ansible-posix-2.2.2.tar.gz, type: file}
roles:
  - {name: acme.logrotate, src: "https://git.acme.example/platform/ansible-role-logrotate.git", scm: git, version: v1.0.0}
```

**Takeaways**
* ansible-core ships only `ansible.builtin`; everything else is a collection you pin. With 2.22 there is no
  community `ansible` 15 bundle yet - core + requirements.yml is the normal setup.
* Air-gapped installs: dependencies of collections are resolved against Galaxy unless you provide them
  (here `community.library_inventory_filtering_v1`, needed by community.general 14). Mirror the closure, or run a
  private Automation Hub / Galaxy NG and point `[galaxy] server_list` at it.
* Restrict `collections_path` in projects so the content is reproducible, not "whatever is on the runner".
* Sources: Galaxy/Automation Hub (`name: ns.coll, version: ==14.0.0`), tarballs (`type: file`), git
  (`type: git`, `name: https://...#/path,ref`), URLs. Pin exact versions or tags; refresh deliberately.
* `ansible-galaxy install -r` handles both sections; `--force` to re-install, `collection verify` to checksum.
