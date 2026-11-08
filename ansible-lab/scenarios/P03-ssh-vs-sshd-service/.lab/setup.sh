ap site.yml
ws_commit "SSH login banner"
printf 'all:\n  children:\n    web:\n      hosts:\n        web1:\n        web2:\n' > inventory/hosts.yml
ws_commit "inventory: web2 (Rocky 9)" "platform team"
ap site.yml || true
ap site.yml
