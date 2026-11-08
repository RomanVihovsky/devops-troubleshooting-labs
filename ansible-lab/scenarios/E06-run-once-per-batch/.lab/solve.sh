cat > site.yml <<'YML'
- name: DB migrations (once per deployment, before the rollout)
  hosts: db
  become: true
  tasks:
    - name: Run DB migrations
      ansible.builtin.shell: echo "$(date +%s) migrate {{ app_version }}" >> /var/lib/acme/migrations.log
      changed_when: true

- name: Rolling app deploy
  hosts: app
  become: true
  serial: 1
  tasks:
    - name: Install the release
      ansible.builtin.copy:
        dest: /opt/app/VERSION
        content: "{{ app_version }}\n"
        mode: "0644"
YML
ap site.yml
