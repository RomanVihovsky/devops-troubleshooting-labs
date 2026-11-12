kx -n market patch svc web -p '{"spec":{"selector":{"app":"web","role":"frontend"}}}' >/dev/null
