printf 'dependencies:\n  - role: nginx_base\n' > roles/shop/meta/main.yml
printf 'dependencies:\n  - role: nginx_base\n' > roles/api/meta/main.yml
sed -i 's|          server_name api.acme.test;|          server_name api.acme.test;\n          client_max_body_size 50m;|' roles/api/tasks/main.yml
ap site.yml
