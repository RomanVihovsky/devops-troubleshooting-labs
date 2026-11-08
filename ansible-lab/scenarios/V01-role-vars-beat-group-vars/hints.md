## Hint 1
`ansible-playbook site.yml -e appserver_workers=8` works - so the variable reaches the template. Something with
higher precedence than group_vars wins. Look at every place the role defines variables.

## Hint 2
Role `vars/main.yml` sits **above** inventory variables in the precedence list (only `set_fact`, include params,
extra vars and a few others beat it). Role `defaults/main.yml` is the lowest level of all.

## Hint 3
Move the tunables from `vars/main.yml` to `defaults/main.yml`. Keep only constants (paths, package names) in `vars/`.
