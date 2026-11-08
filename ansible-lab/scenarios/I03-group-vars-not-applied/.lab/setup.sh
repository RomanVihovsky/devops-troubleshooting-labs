# before the reorganisation: group "webservers", vars in group_vars/webservers.yml, defaults moved to play vars
sed -i 's/web-servers:/webservers:/' inventory/hosts.yml; sed -i 's/hosts: web-servers/hosts: webservers/' site.yml
sed -i '/^  vars:$/,/^    web_tier: unknown$/d' site.yml
ap site.yml
ws_commit "web tier: nginx on 8081, X-Tier header"
cp "$SCN/files/inventory/hosts.yml" inventory/hosts.yml; cp "$SCN/files/site.yml" site.yml
ws_commit "inventory: consistent group naming (tier-servers)" "Alex (platform)"
ap site.yml
