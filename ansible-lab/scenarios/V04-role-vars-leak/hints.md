## Hint 1
Both roles use a variable named `port`. Where does each role define it (`defaults/` or `vars/`)? Which value does
the `web` role's task actually get? (`ansible-playbook site.yml --check --diff`.)

## Hint 2
Role variables are not private: with `roles:` the `vars/main.yml` of **every** role in the play is visible to all
of its roles, and role vars beat role defaults. Each task gets its own role's defaults - but those lose to the
other role's vars.

## Hint 3
Prefix every role variable with the role name (`web_port`, `metrics_port`) - in defaults/vars, tasks and
templates. `ansible-lint --offline -t var-naming roles/` checks it.
