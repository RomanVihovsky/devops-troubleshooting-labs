sed -i 's/app: frontned/app: frontend/' backend-allow.yaml
kx apply -f backend-allow.yaml >/dev/null
