## Hint 1
One pod's logs show a sixth of the traffic. All of them at once: `kubectl -n edge logs -l app=edge --prefix
--tail=200` or `stern -n edge edge --since 5m`.

## Hint 2
Filter for server errors: `stern -n edge edge --since 5m | grep -E ' 5[0-9]{2} '` (access log lines look like
`GET /path 200 ms=...`). Then look for the matching error line.

## Hint 3
`stern -n edge edge --since 5m -i error`.
