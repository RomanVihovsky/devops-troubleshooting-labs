# T13: an empty namespace; OpenBao comes back from the golden with the gw reset after the lab
kns t13
bx kv metadata delete -mount=secret t13/db >/dev/null 2>&1 || true
