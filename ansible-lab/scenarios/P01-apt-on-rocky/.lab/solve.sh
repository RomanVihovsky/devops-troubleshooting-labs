mkdir -p roles/website/vars
printf 'website_package: apache2\nwebsite_service: apache2\n' > roles/website/vars/Debian.yml
printf 'website_package: httpd\nwebsite_service: httpd\n' > roles/website/vars/RedHat.yml
cat > roles/website/tasks/main.yml <<'YML'
- name: OS-specific names
  ansible.builtin.include_vars: "{{ lookup('ansible.builtin.first_found', website_os_vars) }}"
  vars:
    website_os_vars:
      files:
        - "{{ ansible_facts['distribution'] }}.yml"
        - "{{ ansible_facts['os_family'] }}.yml"
      paths:
        - "{{ role_path }}/vars"

- name: Install Apache
  ansible.builtin.package:
    name: "{{ website_package }}"
    state: present

- name: Home page
  ansible.builtin.template:
    src: index.html.j2
    dest: /var/www/html/index.html
    mode: "0644"

- name: Run Apache
  ansible.builtin.service:
    name: "{{ website_service }}"
    state: started
    enabled: true
YML
ap site.yml
