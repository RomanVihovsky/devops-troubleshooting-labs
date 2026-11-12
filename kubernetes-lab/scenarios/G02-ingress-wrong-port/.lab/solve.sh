sed -i 's/port: {number: 80}}}}]/port: {number: 8080}}}}]/' catalog.yaml
kx apply -f catalog.yaml >/dev/null
