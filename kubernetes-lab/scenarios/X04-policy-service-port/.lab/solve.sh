sed -i 's/ports: \[{protocol: TCP, port: 80}\]/ports: [{protocol: TCP, port: 8080}]/' web.yaml
kx apply -f web.yaml >/dev/null
