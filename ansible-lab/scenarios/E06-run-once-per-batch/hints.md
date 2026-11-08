## Hint 1
How does `run_once` interact with `serial`? Count the batches in `ansible-playbook site.yml` output.

## Hint 2
`run_once` means "once per **batch**" - with `serial: 1` and two app nodes there are two batches.
Something that must happen once per deployment belongs outside the rolling play.

## Hint 3
Add a play before the rollout: `hosts: db`, `become: true`, with the migration task (no `delegate_to`, no
`run_once`). Keep `serial: 1` on the app play.
