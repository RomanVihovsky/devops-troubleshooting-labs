# nginx says 403 for a world-readable file
**LNX-112** · P1 · Reporter: shop team

After the "storage cleanup" the shop (`curl localhost/` on srv) returns **403 Forbidden**.
`index.html` is `-rw-r--r--`, nginx is running, the config wasn't touched.

No shortcuts: nothing under `/srv/www` may become world-writable.

**Test**: `curl localhost/` returns 200 with the shop page; no world-writable files or
directories under `/srv/www`.
