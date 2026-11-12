gone() { ! kx -n dbs get database orders-db >/dev/null 2>&1; }
check_eventually 30 "orders-db is gone" gone
check "inventory-db still exists" kx -n dbs get database inventory-db
check "CRD databases.example.com still exists" kx get crd databases.example.com
verdict
