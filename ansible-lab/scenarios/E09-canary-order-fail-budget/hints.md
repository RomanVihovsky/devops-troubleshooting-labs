## Hint 1
Look at the order of the hosts in yesterday's run (`./lab run 'ansible-playbook deploy.yml -e shop_release=4.2.0'` shows
the batches). Who decides the order inside a play, and what did OPS-2950 change? `git log -p deploy.yml`.

## Hint 2
`order:` (`inventory` - the default -, `reverse_inventory`, `sorted`, `reverse_sorted`, `shuffle`) re-sorts the play's
hosts *before* `serial` cuts them into batches. Then do the maths for the batches of two: what percentage is one
failed node, and when does `max_fail_percentage` abort?

## Hint 3
`max_fail_percentage` aborts only when the failed share is **greater than** the value: 1 of 2 = 50 % is not greater than
50. Remove `order: sorted` (the inventory order *is* the rollout order) and use `max_fail_percentage: 0` (or
`any_errors_fatal: true`).
