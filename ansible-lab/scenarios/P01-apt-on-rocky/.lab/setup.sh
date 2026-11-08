ap site.yml
ws_commit "website role (Debian)"
printf 'all:\n  children:\n    web:\n      hosts:\n        web1:\n        web2:\n' > inventory/hosts.yml
ws_commit "inventory: web2 - first Rocky 9 web node" "platform team"
ap site.yml || true
