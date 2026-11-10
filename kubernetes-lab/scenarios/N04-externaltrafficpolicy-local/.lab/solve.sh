sed -i 's/externalTrafficPolicy: Local/externalTrafficPolicy: Cluster/' kiosk.yaml
kx apply -f kiosk.yaml >/dev/null
