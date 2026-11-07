check "getent hosts api.internal -> 10.77.0.20" sx 'getent hosts api.internal | grep -q "^10.77.0.20 "'
check "curl http://api.internal:8080/ -> api OK" sx 'curl -fs --max-time 5 http://api.internal:8080/ | grep -q "api OK"'
verdict
