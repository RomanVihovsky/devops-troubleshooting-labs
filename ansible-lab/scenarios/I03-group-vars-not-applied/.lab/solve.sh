sed -i 's/web-servers:/web_servers:/' inventory/hosts.yml
sed -i 's/hosts: web-servers/hosts: web_servers/' site.yml
git mv group_vars/webservers.yml group_vars/web_servers.yml
# play vars beat group_vars - the fallbacks belong in group_vars/all.yml
sed -i '/^  vars:$/,/^    web_tier: unknown$/d' site.yml
printf 'web_port: 8080\nweb_tier: unknown\n' > group_vars/all.yml
ap site.yml
