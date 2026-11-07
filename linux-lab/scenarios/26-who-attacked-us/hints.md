## Hint 1
Look at a line first: `head -3 /var/log/nginx/access.log.1`. With `awk`'s default
whitespace splitting, which field is the IP, the path, the status code, the timestamp?
## Hint 2
Count-and-rank pattern: `... | sort | uniq -c | sort -rn | head`.
Q1: filter status 404 (`$9 == 404`), print `$1`. Q2: filter path (`$7`), unique IPs, `wc -l`.
## Hint 3
Q3: the timestamp is `[04/Nov/2026:14:37:12` in field 4 - cut out `HH:MM`:
`awk '{print substr($4, 14, 5)}'`.
