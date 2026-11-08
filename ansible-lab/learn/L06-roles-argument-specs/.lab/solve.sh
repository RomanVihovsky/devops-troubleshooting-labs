cat > roles/appconfig/meta/argument_specs.yml <<'YML'
argument_specs:
  main:
    short_description: ACME app environment file
    options:
      appconfig_port:
        type: int
        required: true
        description: Port the app listens on.
      appconfig_mode:
        type: str
        choices: [dev, prod]
        default: prod
      appconfig_features:
        type: list
        elements: str
        default: []
YML
printf 'appconfig_mode: prod\nappconfig_features: []\n' > roles/appconfig/defaults/main.yml
echo 'appconfig_env_file: /etc/default/acme' > roles/appconfig/vars/Debian.yml
echo 'appconfig_env_file: /etc/sysconfig/acme' > roles/appconfig/vars/RedHat.yml
cat > roles/appconfig/tasks/main.yml <<'YML'
- name: OS-specific variables
  ansible.builtin.include_vars: "{{ lookup('ansible.builtin.first_found', params) }}"
  vars:
    params:
      files:
        - "{{ ansible_facts['os_family'] }}.yml"
      paths:
        - "{{ role_path }}/vars"

- name: Environment file
  ansible.builtin.template:
    src: acme.env.j2
    dest: "{{ appconfig_env_file }}"
    mode: "0644"
YML
rm -f roles/appconfig/*/.keep
ap site.yml
