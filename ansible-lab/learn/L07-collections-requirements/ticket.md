# L07 · Collections and requirements: pinned, reproducible, offline
**Learn** · FQCN, requirements.yml, collections_path, roles from git · ~25 min

This repo must not depend on whatever happens to be installed on a laptop or CI image: `ansible.cfg`
uses **only** `./collections` and `./roles`. `site.yml` needs two collections and an internal role:

1. Write `requirements.yml` (one file, two sections):
   * collections `community.general` **14.0.0** and `ansible.posix` **2.2.2** - from the company mirror of
     Galaxy tarballs, mounted at `/opt/collections/` (look at the file names);
   * role `acme.logrotate` from `https://git.acme.example/platform/ansible-role-logrotate.git`, **tag v1.0.0**
     (v1.1.0 is not approved yet).
   Careful: we are air-gapped. If a collection *depends* on another one, ansible-galaxy will try to fetch the
   dependency from galaxy.ansible.com - and fail. Find out what `community.general` needs (its `MANIFEST.json`)
   and list that tarball too.
2. Install: `ansible-galaxy install -r requirements.yml` (collections and roles in one go - into the paths
   from `ansible.cfg`). Check with `ansible-galaxy collection list` and `ansible-galaxy role list`.
3. Run `site.yml`. Installed content is not committed (`.gitignore`) - CI installs it from your file.

**Test**: a fresh checkout installs exactly community.general 14.0.0, ansible.posix 2.2.2 and the role at
v1.0.0, and site.yml converges with them.
