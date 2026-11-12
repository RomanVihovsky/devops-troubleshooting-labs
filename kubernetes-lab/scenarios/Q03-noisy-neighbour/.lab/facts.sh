# Q03: the burner is the Deployment named in .state (setup picks one of five at random)
q03_deploy() { recall q03_burner; }
q03_pod() { kx -n tenants get pods -l app="$(q03_deploy)" -o jsonpath='{.items[0].metadata.name}'; }
