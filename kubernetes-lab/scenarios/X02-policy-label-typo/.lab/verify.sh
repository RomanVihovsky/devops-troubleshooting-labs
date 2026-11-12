check_reach <<'ROWS'
shopx app=frontend backend.shopx.svc:8080 open
shopx app=reports backend.shopx.svc:8080 blocked
ROWS
verdict
