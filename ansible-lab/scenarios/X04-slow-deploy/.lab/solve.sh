sed -i "s/^forks = 1$/forks = 20/" ansible.cfg
python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = s.replace("""        name: "{{ item }}"
        state: present
      loop: [jq, rsync, unzip, git, tar, acl, socat]""", """        name: [jq, rsync, unzip, git, tar, acl, socat]
        state: present""")
for play in ("Web tier", "App tier", "Monitoring agent config"):
    s = s.replace("- name: %s\n" % play, "- name: %s\n" % play, 1)
import re
s = re.sub(r"(- name: (Web tier|App tier|Monitoring agent config)\n  hosts: \w+\n  become: true\n)", r"\1  gather_facts: false\n", s)
open(p, "w").write(s)
PY
ap site.yml
