## Hint 1
Run it yourself: `./lab sh`, then `ci/sanity.sh` (first run ~1 min: ansible-test builds one virtualenv per test from
the company wheelhouse). Each error names the test, file:line and a docs URL. `ci/sanity.sh --test validate-modules`
re-runs one test. `ansible-doc -t module acme.ops.app_flag` needs the collection on a collections path
(`ANSIBLE_COLLECTIONS_PATH=/tmp/ci-sanity`).

## Hint 2
* shebang / missing-python-interpreter: modules must start with `#!/usr/bin/python` (Ansible rewrites it per host).
* validate-modules compares `DOCUMENTATION` with the real `argument_spec` - fix the side that's wrong (the ticket says which).
* pep8: max line length is 160. pylint: the `requests` import is a leftover - nothing uses it.

## Hint 3
`#!/usr/bin/python`; delete the `try: import requests ... except ImportError: pass` block; `choices=['present', 'absent']`;
`default='/etc/shop/flags.conf'`; split the `exit_json(...)` line. Then `ci/sanity.sh` and `ci/smoke.sh`.
