ap site.yml
ws_commit "shop vhost"
sed -i 's|    root /var/www/shop;|    root /var/www/shop;\n    error_page 404 {{ shop_error_page }};|' templates/shop.conf.j2
printf 'shop_server_names: "shop.acme.test,www.acme.test"\nshop_error_page: /404.html\n' > group_vars/all.yml
ws_commit "vhost: optional custom 404 page" "web team"
printf 'shop_server_names:\n  - shop.acme.test\n  - www.acme.test\nshop_error_page: ~   # null = nginx default page\n' > group_vars/all.yml
ws_commit "group_vars cleanup: proper YAML types instead of comma strings" "Platform team"
ap site.yml || true
