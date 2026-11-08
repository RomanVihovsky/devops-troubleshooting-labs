## Hint 1
Where does the job's host list come from? Compare `ansible-inventory --graph` with
`ansible-inventory --graph --flush-cache` (careful: the second one rewrites the cache), then read
`git log -p inventory/`.

## Hint 2
The inventory cache lives on the runner (`/var/tmp/ansible-inventory-cache`) and `cache_timeout: 0` means *never
expire*. Even with fresh data, look at what the plugin returns for a stopped instance: terminated instances are
excluded by default, stopped ones are not.

## Hint 3
For a job that must see the fleet as it is: `cache: false` (or keep the cache for interactive use but run the job
with `--flush-cache`), and `filters: instance-state-name: running`. Delete the stale cache once:
`rm -rf /var/tmp/ansible-inventory-cache` in `./lab sh` (or `ansible-inventory --flush-cache --graph`).
