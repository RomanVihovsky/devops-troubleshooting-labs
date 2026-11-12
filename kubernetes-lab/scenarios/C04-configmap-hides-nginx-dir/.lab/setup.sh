# C04: the ConfigMap is mounted over /etc/nginx - it hides mime.types and everything else from the image
kns web
ka -f nginx.yaml
crashing() { crashlooping web app=web; }
retry 120 crashing || die "nginx did not crash"
