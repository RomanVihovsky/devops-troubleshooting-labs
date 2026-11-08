# Solution - L04

Reference: `.lab/solve.sh`.

**Takeaways**
* Templates see the whole inventory: `groups['web']`, `hostvars[h]['ansible_facts'][...]`
  (facts only if gathered in this run or cached - incident V03).
* `validate:` is the cheapest outage prevention there is (`haproxy -c -f %s`, `nginx -t -c %s` for full
  configs, `visudo -cf %s`, `sshd -t -f %s`).
* `reloaded` vs `restarted`: reload keeps connections; handlers run once, at the end, in handler order.
