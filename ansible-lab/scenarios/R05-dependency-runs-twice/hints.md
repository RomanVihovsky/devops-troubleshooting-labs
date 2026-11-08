## Hint 1
Run `ansible-playbook site.yml --list-tasks`: how many times does *nginx_base* appear? Look at both roles'
`meta/main.yml`.

## Hint 2
A role dependency runs once per play - unless it is listed with **different parameters**: then it runs once per
parameter set. Here each run writes 1m, then 50m. There is only one `00-base.conf`: an http-level setting
cannot be right for both sites.

## Hint 3
Depend on `nginx_base` without parameters (it then runs once, with its 1m default) and put the API's limit
where it belongs: `client_max_body_size 50m;` inside the api `server {}` block.
