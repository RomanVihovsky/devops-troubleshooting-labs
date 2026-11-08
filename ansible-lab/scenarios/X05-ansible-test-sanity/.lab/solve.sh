python3 - plugins/modules/app_flag.py <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("#!/usr/bin/python3\n", "#!/usr/bin/python\n", 1)
s = s.replace('''try:
    import requests  # for the remote flag service (v2)
except ImportError:
    pass

''', "")
s = s.replace("choices=['present', 'absent', 'enabled']", "choices=['present', 'absent']")
s = s.replace("default='/etc/shop/flags')", "default='/etc/shop/flags.conf')")
s = s.replace('''    module.exit_json(changed=changed, previous=previous, msg=('flag %s %s in %s' % (name, 'removed' if state == 'absent' else 'set to %s' % value, path)) if changed else 'unchanged')''',
'''    if not changed:
        msg = 'unchanged'
    elif state == 'absent':
        msg = 'flag %s removed from %s' % (name, path)
    else:
        msg = 'flag %s set to %s in %s' % (name, value, path)
    module.exit_json(changed=changed, previous=previous, msg=msg)''')
open(p, "w").write(s)
PY
run_logged "$SETUP_LOG" ctl "ci/sanity.sh"
