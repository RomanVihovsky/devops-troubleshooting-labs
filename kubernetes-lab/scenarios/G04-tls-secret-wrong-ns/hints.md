## Hint 1
`curl -v --resolve secure.lab:443:192.168.56.200 https://secure.lab/ -k 2>&1 | grep -E 'subject|issuer'`. Then:
in which namespace is `secure-tls` (`kubectl get secret -A | grep secure-tls`)?

## Hint 2
An Ingress's `tls.secretName` is looked up in the **Ingress's namespace**. If it's not there, Traefik falls back
to its default certificate (and logs an error).

## Hint 3
`kubectl -n secure create secret tls secure-tls --cert=workspace/G04/secure.crt --key=workspace/G04/secure.key`
(and remove the stray one from `default`).
