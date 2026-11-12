# C04 - a volume mounted over a directory hides the image's files

**Root cause**: `mountPath: /etc/nginx` mounted the ConfigMap **as** `/etc/nginx`. A mount replaces the
directory's content in the container's view: only `nginx.conf` remained, and `include /etc/nginx/mime.types`
failed. The files are still in the image layer, just hidden under the mount.

**Diagnosis**
```
kubectl -n web logs deploy/web --previous         # open() "/etc/nginx/mime.types" failed
kubectl -n web get deploy web -o jsonpath='{.spec.template.spec.containers[0].volumeMounts}'; echo
kubectl run t --rm -it --image=registry.lab:5000/lab/nginx:1.30-alpine -- ls /etc/nginx   # what the image has
```

**Fix**: mount only the file: `mountPath: /etc/nginx/nginx.conf` + `subPath: nginx.conf`. Or put a server block
into `/etc/nginx/conf.d/` (a directory meant for drop-ins, mounted whole).

**Interview notes**
- Mounts shadow, they don't merge. The same trap: mounting a Secret onto `/etc/ssl/certs`, or a volume onto
  the app's directory.
- `subPath` is the tool for "one file into a populated directory", but it never updates (C02). That's fine
  for nginx, which reads its config at start (`nginx -s reload` would need a new pod or a sidecar).
- Copying `mime.types` into the ConfigMap "works" and freezes a copy of an image file into your config.
