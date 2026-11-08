# L06 · Roles with argument specs and OS-specific variables
**Learn** · role layout, defaults vs vars, `meta/argument_specs.yml`, `first_found` · ~25 min

`roles/appconfig` writes the service environment file for the ACME app - currently a hard-coded Debian
path. Turn it into a reusable role:

1. **Argument spec** `meta/argument_specs.yml` (entry point `main`): `appconfig_port` (int, **required**),
   `appconfig_mode` (str, choices `dev`/`prod`, default `prod`), `appconfig_features` (list of str, default `[]`).
   Ansible then validates inputs before the role runs.
2. **Defaults** for the optional options in `defaults/main.yml`.
3. **OS-specific vars**: the env file lives in `/etc/default/acme` on Debian but `/etc/sysconfig/acme` on
   RedHat-family systems. Put `appconfig_env_file` in `vars/Debian.yml` / `vars/RedHat.yml` and load the right
   one with `include_vars` + `lookup('ansible.builtin.first_found', ...)` keyed by `ansible_facts['os_family']`.
4. `site.yml` calls the role with `appconfig_port: 8443` and features `[search, cart]`.

**Test**: web1 has `/etc/default/acme`, web2 has `/etc/sysconfig/acme` (port 8443, mode prod, features
search,cart); calling the role with `appconfig_mode: chaos` or without a port fails validation; site.yml converges.
