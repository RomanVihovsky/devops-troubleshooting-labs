# Solution - a never-expiring inventory cache, and stopped instances in the inventory

**Root cause**
1. `cache: true` + `cache_timeout: 0` (INC-889): the jsonfile cache on the shared runner **never expires**. Every
   job since then got the fleet of the day the cache was written - shop-web-9 included, shop-web-3 missing.
2. Behind the cache: the plugin excludes *terminated* instances by default, but **stopped** ones are returned -
   shop-web-8 (stopped for forensics) is unreachable. No `instance-state-name` filter.

**Fix**
```yaml
filters:
  tag:Env: prod
  instance-state-name: running
# cache removed (or: keep it for interactive use, and run the job with --flush-cache)
```
Delete the stale cache once (`rm -rf /var/tmp/ansible-inventory-cache` or `--flush-cache`).

**Interview notes**
* Inventory caching trades freshness for API calls: fine for interactive `ansible-inventory`, wrong for a deploy job
  in an autoscaled fleet. If you need it (API throttling), keep `cache_timeout` short and flush at the start of jobs.
* `cache_timeout: 0` means *never expires* for the file-based cache plugins.
* Dynamic inventories should filter on state (`running`) and environment tags; a stopped instance is a host that
  will always be unreachable.
