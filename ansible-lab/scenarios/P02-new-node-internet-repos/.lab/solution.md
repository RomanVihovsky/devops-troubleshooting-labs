# Solution - repository configuration is part of the play

**Root cause**: the vendor image enables Rocky's public repos (`baseos`, `appstream`, `extras`). The network is
air-gapped, so dnf can't download their metadata - and dnf refuses to work while an enabled repo is unreachable.

**Fix**: `pre_tasks` that configure the internal mirror and remove the vendor repo sections, before any package
task. Every new node from the same image now converges in one run.

**Interview notes**
* Bootstrap order matters: repos -> packages -> config. `pre_tasks` run before roles.
* `skip_if_unavailable=True` would hide a broken mirror - better to be explicit about the only allowed source.
* In real life: Satellite/Pulp/Artifactory/Nexus mirrors with GPG keys (`gpgkey:` + `gpgcheck: true`),
  or bake the repo config into the golden image (Packer) - and still enforce it in Ansible.
