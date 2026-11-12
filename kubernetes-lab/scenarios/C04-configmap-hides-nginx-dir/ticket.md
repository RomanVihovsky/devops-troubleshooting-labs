# Our nginx crash-loops since we gave it its own nginx.conf
**INC-2439** · P2 · Reporter: team web

We put our `nginx.conf` into the ConfigMap `nginx-conf` and mounted it into the container
(`workspace/C04/nginx.yaml`). Now nginx exits at start: *open() "/etc/nginx/mime.types" failed (2: No such
file or directory)*. The file is part of the image! Keep **our** `nginx.conf` - it answers with our
`X-Served-By: web-c04` header.

**Test**: `web` Ready (2 pods); `http://web.web.svc/` answers 200 with the header `X-Served-By: web-c04` (our
config is active); the image's own `/etc/nginx/mime.types` is in use (not copied into the ConfigMap).
