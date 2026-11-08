# Solution - L02

Reference: `.lab/solve.sh`.

**Takeaways**
* `ansible.builtin.package` picks apt/dnf from facts; package *names* still differ between distros
  sometimes (P01) - nginx happens to be the same.
* Distro defaults differ (Debian's default site uses `/var/www/html`, Rocky's `/usr/share/nginx/html`) -
  owning the server block makes the role predictable.
* Idempotence = the second run reports `ok`. `--check --diff` previews changes without making them.
* Handlers run once at the end of the play (or at `meta: flush_handlers`), however many tasks notify them.
