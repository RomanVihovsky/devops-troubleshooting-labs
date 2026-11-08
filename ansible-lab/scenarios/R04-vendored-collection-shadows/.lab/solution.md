# Solution - a vendored collection shadows the installed one

**Root cause**: `collections_path = ./collections:/usr/share/ansible/collections`. The repo vendors
community.general **12.0.0** (2024) in `./collections`; it is found first, so the whole 14.0.0 install is
invisible. `logrotate` was added in 12.5.0.

**Fix**: delete the vendored copy (the whole directory) and its path entry; declare needs in `requirements.yml`.
Removing only the config entry is not enough: Ansible implicitly searches `collections/` next to the playbook,
and even a half-deleted tree (files git never tracked) shadows the real collection.

**Interview notes**
* Resolution is per collection, first match on the path wins; `ansible-galaxy collection list` shows all copies.
* `ansible-config dump --only-changed` reveals repo-level path overrides.
* For air-gapped runners: build an Execution Environment (L12) or install from a private Automation Hub -
  don't commit `ansible_collections/` trees.
* `community.general.collection_version` lookup prints what actually resolved.
