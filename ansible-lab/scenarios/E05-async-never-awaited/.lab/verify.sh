label="verify-$RANDOM"
dump="$CI/backups/app1-acme.sql"
same_as_node() { nx app1 "cat /var/backups/acme/acme.sql" | cmp -s - "$dump"; }
check "backup.yml runs" applies backup.yml -e "backup_label=$label"
check "the shipped dump is complete (trailer of this run)" grep -qx -- "-- ACME dump complete $label" "$dump"
check "the shipped dump equals the one on app1" same_as_node
check "the dump still runs asynchronously" eval 'grep -qE "^ *async: *[0-9]+" "$CI/backup.yml"'
verdict
