python3 - rulebooks/web.yml <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace('''      condition: event.payload.check == "nginx" and event.payload.status == "down"
''', '''      condition: event.payload.check == "nginx" and event.payload.status == "down"
      # at most one remediation per host in 10 minutes; monitoring re-sends every 15 s while failing
      throttle:
        once_within: 10 minutes
        group_by_attributes:
          - event.payload.host
''')
open(p, "w").write(s)
PY
grep -q once_within rulebooks/web.yml
eda_restart /work
