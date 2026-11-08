python3 - deploy.yml <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace('''    - name: Cluster membership
''', '''# A play boundary is a barrier: every node has finished the per-node part (and set shop_node_id) before any node
# renders the cluster file. The default (linear) strategy is fine here - these steps are fast.
- name: Shop cluster membership
  hosts: shop
  become: true
  gather_facts: false
  tasks:
    - name: Cluster membership
''')
open(p, "w").write(s)
PY
ap deploy.yml
