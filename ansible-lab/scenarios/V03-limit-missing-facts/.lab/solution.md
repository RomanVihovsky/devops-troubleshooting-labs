# Solution - gather facts for hosts outside --limit

**Root cause**: the template reads `hostvars['db1']['ansible_facts']['all_ipv4_addresses'][0]`. Facts exist only for hosts
whose play ran in this execution (or from a fact cache). `--limit web` skips the db play -> empty facts.

**Fix**: in the web play, `ansible.builtin.setup` delegated to the db hosts with `delegate_facts: true`
(only when missing), or avoid facts for cross-host data (inventory variable `db_host`, DNS name).

**Interview notes**
* `--limit` restricts the hosts tasks run on - not just "which plays"; cross-host references break silently.
* Fact caching (`jsonfile`, `redis`) helps only if warm - a fresh CI runner has an empty cache.
* `delegate_facts: true` stores facts under the delegated host; without it they land on the current host.
* Prefer stable names (`db1.acme.internal`) over IPs from facts when you can.
