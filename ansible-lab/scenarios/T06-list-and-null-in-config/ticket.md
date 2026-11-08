# Shop deploy fails at "Validate nginx config" since the group_vars cleanup
**OPS-275** · P2 · Reporter: web team

Two harmless-looking commits this week (see `git log`): an optional custom 404 page and a group_vars cleanup
("proper YAML types instead of comma strings"). Since then the deploy fails in the handler:
```
nginx: [emerg] invalid number of arguments in "error_page" directive
```
Keep the data as it is now: `shop_server_names` is a list, `shop_error_page: ~` means "nginx default page".

**Test**: site.yml deploys and converges; http://shop.acme.test and http://www.acme.test (on web1) serve the shop;
the rendered vhost holds no Python list syntax; setting `shop_error_page` still renders an `error_page` line.
