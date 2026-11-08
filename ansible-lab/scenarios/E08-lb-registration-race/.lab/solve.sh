python3 - deploy.yml <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace('''      changed_when: lb_add.stdout is search('^added')
      delegate_to: lb1
''', '''      changed_when: lb_add.stdout is search('^added')
      delegate_to: lb1
      # lb-register is read-modify-write without a lock: one registration at a time, the rest stays parallel
      throttle: 1
''')
open(p, "w").write(s)
PY
grep -q 'throttle: 1' deploy.yml
ap deploy.yml
