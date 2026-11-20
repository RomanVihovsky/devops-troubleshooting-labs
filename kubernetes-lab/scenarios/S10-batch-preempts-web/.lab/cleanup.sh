# the student re-creates batch-high (or adds a class for storefront) from files without the lab label
for p in $(kx get priorityclass -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  case $p in system-*) ;; *) kx delete priorityclass "$p" --ignore-not-found >/dev/null 2>&1 ;; esac
done
true
