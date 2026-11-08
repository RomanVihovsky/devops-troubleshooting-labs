cat > group_vars/all.yml <<'YML'
nginx_settings_defaults:
  gzip: "on"
  keepalive_timeout: 65
  client_max_body_size: 10m
nginx_settings_overrides: {}
nginx_settings: "{{ nginx_settings_defaults | combine(nginx_settings_overrides) }}"
YML
printf 'nginx_settings_overrides:\n  client_max_body_size: 50m   # bigger uploads for prod (OPS-238)\n' > group_vars/prod.yml
ap site.yml
