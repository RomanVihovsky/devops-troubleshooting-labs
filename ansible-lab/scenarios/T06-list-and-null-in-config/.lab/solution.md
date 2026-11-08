# Solution - render types, not their Python representation

**Root cause** (two):
1. `shop_error_page: ~` is null; `{{ shop_error_page }}` renders an empty string -> `error_page 404 ;` ->
   `nginx -t` fails in the handler (and the bad file stays on disk).
2. `shop_server_names` became a list; `replace(',', ' ')` is a string filter - on a list it renders
   `['shop.acme.test'  'www.acme.test']`. nginx accepts it (with a "suspicious symbols" warning) and the
   requests fall through to the default site.

**Fix**: `join(' ')` for lists; `{% if %}` around optional directives (or a real default).

**Interview notes**
* Since 2.19 templates keep native types - a value's type is decided by the data, not by string round-trips.
  Changing a var from a string to a list is an interface change for every template that uses it.
* Validate rendered configs: `template: validate:` for whole files, a handler `nginx -t` for snippets.
* Argument specs (`meta/argument_specs.yml`, type: list) would have caught the type change at the role boundary.
