## Hint 1
Why does a fresh checkout behave differently from your laptop? Compare
`.terraform/modules/modules.json` and what `terraform init` would download now. Look at the module source.

## Hint 2
`?ref=main` follows a branch: every fresh `init` takes whatever was merged there last.
`git ls-remote https://git.acme.example/platform/tf-module-web-config.git` shows tags and branches.

## Hint 3
Pin `?ref=v1.2.0` (or the commit SHA behind it), `terraform init -upgrade`, plan -> no changes.
Take newer versions deliberately, in a PR, after reading their changelog.
