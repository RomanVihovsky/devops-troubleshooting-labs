sed -i 's/targetPort: http}/targetPort: web}/' maps.yaml
kx apply -f maps.yaml >/dev/null
