# L12 · Execution Environments: build one, run your playbook in it
**Learn** · `execution-environment.yml` v3, ansible-builder, running playbooks in an EE · ~30 min

"Works on my machine" ends here: an Execution Environment is a container image with ansible-core, the
collections and the Python libraries a project needs - the same image on laptops, CI and AAP.

`site.yml` uses the `community.general.json_query` filter, which needs the Python library **jmespath**.
Build an EE for it:

1. Complete `ee/execution-environment.yml` (version 3): base image `ansiblelab/ee-base:1` (ansible-core 2.22,
   ansible.posix, community.general already inside) and the Python dependency `jmespath`. The air-gap
   plumbing (offline wheelhouse) is already there - read it.
2. Copy the company wheelhouse into the build: `cp -r /opt/wheels ee/wheels`, then in `ee/`:
   `ansible-builder create` (writes `ee/context/`).
3. On the host: `./lab ee build ee acme/ee:1` (Docker builds the context - offline).
4. `./lab ee run acme/ee:1 site.yml` - the playbook runs **inside** the EE against web1.

**Test**: image `acme/ee:1` exists, runs ansible-core 2.22.0 and imports jmespath; `site.yml` converges when run
inside the EE; `/etc/acme/services.txt` on web1 lists the public services.
