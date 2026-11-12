up() { pods_get zt app=client /upstream | jq -se 'length > 0 and all(.[]; .status == 200)' >/dev/null 2>&1; }
deny_kept() { [ "$(kx -n zt get networkpolicy default-deny -o jsonpath='{.spec}' 2>/dev/null)" = "$(recall x01_deny)" ]; }
nothing_else() { ! kx -n zt exec deploy/client -- labapp get --timeout 3 http://192.168.56.20:8080/ >/dev/null 2>&1; }
check_eventually 60 "client -> backend works (/upstream 200)" up
check "default-deny unchanged" deny_kept
check "client can't reach 192.168.56.20:8080" nothing_else
verdict
