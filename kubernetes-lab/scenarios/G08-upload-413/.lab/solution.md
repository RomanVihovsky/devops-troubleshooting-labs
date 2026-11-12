# G08 - a body limit at the edge

**Root cause**: the Ingress uses the Traefik middleware `upload-limit` (`buffering.maxRequestBodyBytes:
1048576`). Traefik buffers the request body and rejects anything above 1 MiB with **413** before the app sees it.
The app's own limit (64 MiB) never came into play.

**Diagnosis**
```
curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: media.lab' --data-binary @<(head -c 2M /dev/zero) http://192.168.56.200/upload
kubectl -n media logs deploy/media | grep -c upload          # the app never saw it
kubectl -n media get ingress media -o jsonpath='{.metadata.annotations}'; echo
kubectl -n media get middleware upload-limit -o yaml
```

**Fix**: raise the limit to what the business needs (16 MiB), still below the app's 64 MiB.

**Interview notes**
- Every hop can have its own limit: LB, ingress (`client_max_body_size` in nginx, the `buffering` middleware in
  Traefik), the app server, the app. The first one that says no answers, and its error page tells you which.
- Buffering protects slow backends from slow uploads, but costs memory/disk at the ingress
  (`memRequestBodyBytes` decides when it spills to disk).
- Large files are better uploaded straight to object storage (pre-signed URLs) than streamed through the
  ingress and the app.
