## Hint 1
Look at the rendered file: `ansible-playbook site.yml --check --diff`. What does `{{ shop_error_page }}`
render when the value is null? What does `replace(',', ' ')` do to a **list**?

## Hint 2
A null renders as an empty string - the directive loses its argument. A filter meant for strings applied to a
list renders the list's Python representation. Fix the error page first - then check *which site* answers
for shop.acme.test.

## Hint 3
`server_name {{ shop_server_names | join(' ') }};` and
`{% if shop_error_page %}error_page 404 {{ shop_error_page }};{% endif %}` (lines inside the server block).
