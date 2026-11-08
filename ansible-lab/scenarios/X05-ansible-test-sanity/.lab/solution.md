# Solution - make code, documentation and packaging rules agree (no ignore file)

**Root cause** - `ansible-test sanity` found real defects, not style:
* **shebang** / `missing-python-interpreter`: modules must start with `#!/usr/bin/python`; Ansible rewrites it to the
  target's interpreter (`ansible_python_interpreter`); `#!/usr/bin/python3` bypasses that (and `#!/usr/bin/env python3` does not even run on 2.22: "The module interpreter ... was not found").
* **validate-modules** `doc-choices-do-not-match-spec`: the code accepted `state=enabled` (undocumented, unimplemented -
  it would have *set* the flag); `doc-default-does-not-match-spec`: the code wrote `/etc/shop/flags`, a file the shop
  never reads. The smoke test passed only because it always set `path:` explicitly.
* **pylint** `unused-import`: a guarded `import requests` leftover.
* **pep8** E501: a 182-character line (limit 160).

**Fix**: `#!/usr/bin/python`; delete the import; `choices=['present', 'absent']`; `default='/etc/shop/flags.conf'`; split
the long line. `ci/sanity.sh` and `ci/smoke.sh` pass.

**Interview notes**
* `ansible-test sanity` (collection checked out at `ansible_collections/<ns>/<name>`) runs ~24 tests: validate-modules
  (docs vs argument_spec, return docs), import (module imports on a minimal target), pylint, pep8, yamllint, shebang,
  compile... `--test X` runs one; `--docker` uses the default test container, offline you need the requirements
  (here: a pip wheelhouse - ansible-test bootstraps pip per test venv).
* Ignore files (`tests/sanity/ignore-X.Y.txt`) exist for genuine exceptions and are reviewed; Galaxy/AAP certification
  rejects most ignores.
* Also: `ansible-test units` (pytest, mocking AnsibleModule) and `ansible-test integration` (targets in
  `tests/integration/targets/`).
