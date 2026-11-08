ap site.yml
ws_commit "nginx tuning"
printf 'nginx_settings:\n  client_max_body_size: 50m   # bigger uploads for prod (OPS-238)\n' > group_vars/prod.yml
ws_commit "prod: 50m uploads" "Robin (web)"
ap site.yml
