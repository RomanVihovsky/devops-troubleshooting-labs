sed -i "s/{{ shop_server_names | replace(',', ' ') }}/{{ shop_server_names | join(' ') }}/" templates/shop.conf.j2
sed -i 's/^    error_page 404 {{ shop_error_page }};/{% if shop_error_page %}\n    error_page 404 {{ shop_error_page }};\n{% endif %}/' templates/shop.conf.j2
ap site.yml
