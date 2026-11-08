## Hint 1
ansible-core 2.22 masks values it knows are secrets (vault values, `no_log` parameters, `register_secret`)
as `$REDACTED$` in all output - including `debug`. That is a feature, not a bug.

## Hint 2
Stdout is the wrong channel for a secret anyway: CI logs are kept, shared and indexed. Hand it over through a
file only the CI user can read, outside git.

## Hint 3
In the localhost play: `ansible.builtin.copy` with `dest: "{{ playbook_dir }}/.ci/smoke-token"`,
`content: "{{ api_token }}"`, `mode: "0600"` (`.ci/` is git-ignored). In `ci/pipeline.sh`:
`TOKEN=$(cat .ci/smoke-token)`, and remove the file after the smoke test.
