## Hint 1
`kubectl -n payments-ui describe pod <pod>`. Which image tag is used? `curl -s
http://192.168.56.20:5000/v2/lab/labapp/tags/list`.

## Hint 2
`runAsNonRoot` makes the kubelet refuse an image whose USER is root (0) unless the pod sets a non-zero
`runAsUser`. The `-root` tag is the root build.

## Hint 3
Use `labapp:1.4` (the standard build runs as an unprivileged user), apply. Setting `runAsUser: 10001` on
the root image would work too - if the image's files allow it.
