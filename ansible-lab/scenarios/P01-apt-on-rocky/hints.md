## Hint 1
`ansible.builtin.apt` exists only on Debian-family systems. And the package and service are not called
`apache2` everywhere: `ansible web2 -m ansible.builtin.package_facts` / `dnf list httpd` on Rocky.

## Hint 2
Use the generic `ansible.builtin.package` and `ansible.builtin.service` modules; keep the OS-specific *names*
in variables loaded per OS family (`vars/Debian.yml`, `vars/RedHat.yml`).

## Hint 3
```yaml
- name: OS-specific names
  ansible.builtin.include_vars: "{{ lookup('ansible.builtin.first_found', website_os_vars) }}"
  vars:
    website_os_vars:
      files: ["{{ ansible_facts['distribution'] }}.yml", "{{ ansible_facts['os_family'] }}.yml"]
      paths: ["{{ role_path }}/vars"]
```
`Debian.yml`: `website_package: apache2`, `website_service: apache2`; `RedHat.yml`: `httpd` / `httpd`.
