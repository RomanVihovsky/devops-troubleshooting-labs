## Hint 1
`ansible-inventory --host web1 | jq .nginx_settings` - compare with web2. What happened to the other keys?

## Hint 2
When the same variable is defined at two levels, the higher one **replaces** the whole value - dictionaries are
not merged (unless you change `hash_behaviour` globally, which is deprecated in spirit and surprises everyone).

## Hint 3
Keep the shared values in `nginx_settings_defaults` (all.yml), put only the differences in `nginx_settings_overrides`
(prod.yml), and merge explicitly: `nginx_settings: "{{ nginx_settings_defaults | combine(nginx_settings_overrides | default({})) }}"`.
