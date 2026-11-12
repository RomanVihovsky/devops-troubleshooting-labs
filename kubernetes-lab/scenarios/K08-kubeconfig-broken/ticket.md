# My kubeconfig broke after I "tidied it up"
**INC-2380** · P4 · Reporter: dana (SRE)

I merged two kubeconfigs and renamed a few things. Now `KUBECONFIG=workspace/K08/kubeconfig kubectl get pods`
fails, and after the first fix it still doesn't show what I expect. My colleagues' kubectl works fine. I'm
user `dana` (view access to the whole cluster); my default namespace should be `shop`. The API endpoint for
desktops is `https://192.168.56.20:6443`.

**Test**: with `workspace/K08/kubeconfig` (and no other kubeconfig), `kubectl auth whoami` says `dana` and
`kubectl get pods` lists the pods of `shop`, through `https://192.168.56.20:6443` with TLS verified (no
`insecure-skip-tls-verify`).
