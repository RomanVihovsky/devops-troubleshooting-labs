for d in $(kx -n dbs get databases.example.com -o name 2>/dev/null); do kx -n dbs patch "$d" --type merge -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1; done
true
