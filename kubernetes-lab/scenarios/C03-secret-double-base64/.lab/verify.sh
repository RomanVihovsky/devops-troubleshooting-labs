pw=$(recall c03_pw)
dec() { kx -n cart get secret "$1" -o jsonpath='{.data.password}' | base64 -d; }
redis_ok() { pods_get cart app=cart /ready | jq -se 'length >= 2 and all(.[]; .checks.redis == "ok")' >/dev/null 2>&1; }
requires_pw() { [ "$(kx -n cart exec deploy/redis -- redis-cli -a "$pw" --no-auth-warning ping 2>/dev/null)" = PONG ] \
                && [ "$(kx -n cart exec deploy/redis -- redis-cli ping 2>&1)" != PONG ]; }
check_eventually 150 "cart: 2 Ready pods" deploy_ready cart cart 2
check_eventually 60 "cart talks to Redis (hit counter / readiness)" redis_ok
check "cart-redis decodes to redis-auth's password" test "$(dec cart-redis)" = "$pw"
check "redis-auth unchanged and Redis still requires it" requires_pw
verdict
