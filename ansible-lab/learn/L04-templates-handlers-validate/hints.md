## Hint 1
```jinja
backend web
    balance {{ haproxy_balance }}
    option httpchk GET /health
{% for h in groups['web'] %}
    server {{ h }} {{ h }}:8080 check
{% endfor %}
```

## Hint 2
`validate:` runs a command against the rendered **temporary** file (`%s`) before it replaces the real one.
If the command fails, the task fails and the destination is unchanged.

## Hint 3
Handler `Reload haproxy` = `ansible.builtin.service: name=haproxy state=reloaded`; template task
`notify: Reload haproxy`; a final `ansible.builtin.service: name=haproxy state=started enabled=true`.
