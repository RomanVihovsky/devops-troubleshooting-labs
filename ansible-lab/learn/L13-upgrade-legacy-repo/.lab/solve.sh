python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = s.replace('# written for ansible-core 2.16 (2023) - see the porting guides for 2.19, 2.20, 2.21, 2.22', '# ported to ansible-core 2.22')
s = s.replace('create_dirs: "yes"', 'create_dirs: true')
s = s.replace('that: "{{ app_port }} > 1024"', 'that: app_port > 1024')
s = s.replace('loop: "{{ range(1, 4) }}"\n      when: create_dirs', 'loop: "{{ range(1, 4) | list }}"\n      when: create_dirs | bool')
s = s.replace('mode: "{{ item.mode }}"', 'mode: "{{ item.mode | default(omit) }}"')
s = s.replace('- {name: legacy.conf, mode: "{{ omit }}"}', '- {name: legacy.conf}')
s = s.replace("{{ ansible_distribution }} {{ ansible_distribution_major_version }} ({{ play_hosts | length }} hosts in play)",
              "{{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_major_version'] }} ({{ ansible_play_hosts | length }} hosts in play)")
s = s.replace('follow_redirects: yes', 'follow_redirects: safe')
open(p, "w").write(s)
PY
ap site.yml
