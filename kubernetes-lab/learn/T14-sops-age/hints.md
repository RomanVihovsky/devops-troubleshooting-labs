## Hint 1
`encrypted_regex: ^(data|stringData)$` encrypts only those values: `apiVersion`, `kind`, `metadata` stay
readable (reviewable diffs). `sops -e -i secrets/t14.yaml` uses the first matching `creation_rules` entry by
path - run it from the repo root.

## Hint 2
Several recipients: `age: age1lab...,age1team...` (comma-separated) in the rule. `sops updatekeys
secrets/t14.yaml` re-encrypts the file's data key for the rule's current recipients - the values stay
untouched.

## Hint 3
Check before pushing: `git diff --cached | grep "$(cat ../T14/password.txt)"` must print nothing.
`SOPS_AGE_KEY_FILE=<a key file> sops -d secrets/t14.yaml` decrypts with a specific key. If plaintext got
committed: rewriting history is not enough once it was pushed - rotate the secret.
