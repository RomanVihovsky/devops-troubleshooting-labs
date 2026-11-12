check_reach <<'ROWS'
payx app=client 192.168.56.20:8080 open
payx app=client 192.168.56.20:22 blocked
payx app=client 192.168.56.31:22 blocked
ROWS
verdict
