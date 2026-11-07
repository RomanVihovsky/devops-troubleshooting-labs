# Solution - log analysis with awk / sort / uniq

```
L=/var/log/nginx/access.log.1
# 1. top IP by 404s
awk '$9 == 404 {print $1}' $L | sort | uniq -c | sort -rn | head -3
# 2. distinct IPs that requested /wp-login.php
awk '$7 == "/wp-login.php" {print $1}' $L | sort -u | wc -l
# 3. busiest minute
awk '{print substr($4, 14, 5)}' $L | sort | uniq -c | sort -rn | head -3
```
Fields in the combined log format (whitespace split): `$1` client IP, `$4` `[dd/Mon/yyyy:HH:MM:SS`,
`$6` `"GET`, `$7` path, `$9` status, `$10` bytes. The user agent contains spaces - so count
fields from the left, never from the right (`$NF`).

**Interview notes**: the `sort | uniq -c | sort -rn | head` idiom answers 80% of these
questions. Know `cut -d' ' -f`, `grep -c`, `awk` associative arrays
(`awk '{c[$1]++} END {for (i in c) print c[i], i}'`), `zcat`/`zgrep` for rotated `.gz`
logs, and `jq` for JSON logs. Watch out for proxies: the real client may be in
`X-Forwarded-For`, not `$1`.
