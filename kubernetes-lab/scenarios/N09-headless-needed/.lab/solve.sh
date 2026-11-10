sed -i 's|^  selector: {app: ring}|  clusterIP: None\n  selector: {app: ring}|' ring.yaml
kx -n ring delete svc peers >/dev/null
kx apply -f ring.yaml >/dev/null
