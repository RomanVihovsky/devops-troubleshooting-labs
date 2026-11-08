# Solution - L03

Inventory groups `prod`/`staging` + `group_vars/{prod,staging,web}.yml` + `host_vars/web2.yml`; the role
untouched.

**Takeaways**
* Role **defaults** are meant to be overridden; role **vars** (`vars/main.yml`) are not - they beat inventory
  variables (incident V01).
* Same-level groups merge by name order unless you set `ansible_group_priority`; child groups beat parents.
* `-e` always wins - great for one-offs, dangerous in CI templates.
* Dicts are replaced, not merged (incident V02) - use `combine()` deliberately.
