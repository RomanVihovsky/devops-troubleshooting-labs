sed -i 's/targetPort: 80}/targetPort: http}/' weather.yaml
kx apply -f weather.yaml >/dev/null
