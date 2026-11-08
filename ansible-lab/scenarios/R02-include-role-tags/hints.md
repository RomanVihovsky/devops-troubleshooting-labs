## Hint 1
Run `ansible-playbook site.yml --tags deploy --list-tasks`. Which tasks are selected?

## Hint 2
Tags on `include_role` (dynamic) apply to the **include task only** - the tasks loaded from the role keep their
own (empty) tags and are filtered out by `--tags deploy`. `import_role` (static) copies the tags onto every task.

## Hint 3
Either `ansible.builtin.import_role: {name: app}` with `tags: [deploy]`, or keep `include_role` and add
`apply: {tags: [deploy]}` next to `tags: [deploy]`.
