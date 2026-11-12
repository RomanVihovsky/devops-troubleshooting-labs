sed -i 's|- {name: conf, mountPath: /etc/nginx}|- {name: conf, mountPath: /etc/nginx/nginx.conf, subPath: nginx.conf}|' nginx.yaml
kx apply -f nginx.yaml >/dev/null
wait_rollout web deploy/web 180
