## Hint 1
Run it like CI does, from a clean checkout: `git stash -u; rm -rf stacks/ledger/.terraform; ci/plan.sh prod`.
Why does it work on the author's machine? (Hint: what is cached in `.terraform/`?)

## Hint 2
`git show --stat HEAD` - which files did the cleanup touch? What does `ci/plan.sh` look for?

## Hint 3
Point the script at `backend/<env>.s3.tfbackend`, and make it fail loudly when the file is missing
instead of silently running `init` without a backend config.
