mkdir -p roles/sshd_banner/vars
printf 'sshd_banner_service: ssh\n' > roles/sshd_banner/vars/Debian.yml
printf 'sshd_banner_service: sshd\n' > roles/sshd_banner/vars/RedHat.yml
python3 - <<'PY'
p = "roles/sshd_banner/tasks/main.yml"
s = open(p).read()
s = """- name: OS-specific names
  ansible.builtin.include_vars: "{{ ansible_facts['os_family'] }}.yml"

""" + s
open(p, "w").write(s)
PY
printf -- '- name: Restart sshd\n  ansible.builtin.service:\n    name: "{{ sshd_banner_service }}"\n    state: reloaded\n' > roles/sshd_banner/handlers/main.yml
run_logged "$SETUP_LOG" ctl "ansible web2 -b -m ansible.builtin.service -a 'name=sshd state=reloaded'"
ap site.yml
