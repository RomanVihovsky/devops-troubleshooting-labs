## Hint 1
`systemctl list-unit-files | grep ssh` on both nodes (`./lab node web1`, `./lab node web2`).

## Hint 2
Debian calls the unit `ssh`, Rocky calls it `sshd`. Put the name in an OS-specific variable. And remember R01:
why are the later runs green although web2's sshd never picked up the drop-in?

## Hint 3
`vars/Debian.yml` -> `sshd_banner_service: ssh`, `vars/RedHat.yml` -> `sshd`, loaded with `include_vars` (or
`first_found`), handler `name: "{{ sshd_banner_service }}"`, `state: reloaded`. Then restart sshd on web2 once
(the notification was lost with the failed run).
