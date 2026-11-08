# Solution - facts via ansible_facts only

**Root cause**: the role reads injected top-level facts (`ansible_os_family`, `ansible_hostname`, ...). With
`INJECT_FACTS_AS_VARS=False` (the 2.24 default) they don't exist: `include_vars` fails loudly - and
`ansible_python_version | default('n/a')` fails **silently**, writing `"python": "n/a"` to the CMDB.

**Fix**: `ansible_facts['os_family']` etc. everywhere; drop the `default()` that hid the problem.
Leave magic/connection variables (`ansible_check_mode`, `ansible_host`, `inventory_hostname`) alone.

**Interview notes**
* 2.20 deprecated the injection; 2.22 prints the origin `file:line:col` of every injected-fact use.
* `ansible_facts['x']` vs `ansible_facts.x`: both work; brackets are safer for keys like `default_ipv4`.
* A `default()` on a value that "always exists" hides breakage - prefer failing loudly.
* `hostvars[h]['ansible_facts']` is the cross-host form (see V03).
