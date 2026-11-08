python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = s.replace("""  become: true
  tasks:""", """  become: true
  pre_tasks:
    - name: Internal package mirror (air-gapped network)
      ansible.builtin.yum_repository:
        name: acme-rocky9
        description: ACME internal mirror (Rocky 9)
        file: acme
        baseurl: http://repo.acme.internal/rocky9
        gpgcheck: false
      when: ansible_facts['os_family'] == 'RedHat'
    - name: Vendor repositories off
      ansible.builtin.yum_repository:
        name: "{{ item.name }}"
        file: "{{ item.file }}"
        state: absent
      loop:
        - {name: baseos, file: rocky}
        - {name: appstream, file: rocky}
        - {name: extras, file: rocky-extras}
      when: ansible_facts['os_family'] == 'RedHat'
  tasks:""")
open(p, "w").write(s)
PY
ap site.yml
