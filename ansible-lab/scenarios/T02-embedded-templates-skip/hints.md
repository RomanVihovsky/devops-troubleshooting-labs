## Hint 1
Run `ansible-playbook site.yml -v` and look at the *Production hardening marker* task on web1: skipped. Then run
it once with `ANSIBLE_ALLOW_EMBEDDED_TEMPLATES=True` - what do the warnings say?

## Hint 2
`when:` is already a Jinja expression. `'{{ inventory_hostname }}'` inside it is an *embedded template* in a
string constant: with the 2.23 default it is no longer rendered - the literal text `{{ inventory_hostname }}`
is compared, and it is never in `groups['prod']`.

## Hint 3
Write bare expressions: `when: inventory_hostname in groups['prod']` and `when: item.enabled`
(a `when` wrapped in `{{ }}` is removed in 2.23 as well).
