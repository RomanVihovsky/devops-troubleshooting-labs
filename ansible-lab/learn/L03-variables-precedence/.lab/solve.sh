cat > inventory/hosts.yml <<'YML'
all:
  children:
    web:
      hosts:
        web1:
        web2:
    prod:
      hosts:
        web1:
    staging:
      hosts:
        web2:
YML
echo 'motd_env: prod' > group_vars/prod.yml
echo 'motd_env: staging' > group_vars/staging.yml
echo 'motd_contact: web-oncall@acme.example' > group_vars/web.yml
echo 'motd_owner: Team Rocky' > host_vars/web2.yml
ap site.yml
