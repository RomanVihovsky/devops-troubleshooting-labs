## Hint 1
What does `lookup('ansible.builtin.file', ...)` return - a template, or data? Up to 2.18 Ansible re-templated
anything that *looked* like a template, wherever it came from.

## Hint 2
Since 2.19 content from files, lookups, module results and facts is **untrusted**: it is never rendered as a
template (that closed a whole class of injection bugs). Only templates from trusted sources are rendered.

## Hint 3
Render it on purpose: `ansible.builtin.template` with `src: templates/motd.j2`, or
`content: "{{ lookup('ansible.builtin.template', 'templates/motd.j2') }}"`.
