# Solution - never point a module at a branch

**Root cause**: `?ref=main`. Your laptop still has the September copy in `.terraform/modules`; a fresh
CI checkout downloads today's `main`, which changed defaults and added a parameter. Same repo, different
result depending on *when* you ran `init`.

**Fix**: `?ref=v1.2.0` (or the commit SHA), `terraform init -upgrade`. Upgrade later on purpose.

**Interview notes**
* Tags are mutable too (force-push); commit SHAs are not. Registries with checksums (private registry,
  OCI) give integrity. Terragrunt `catalog` / `scaffold` pin refs for you.
* Reproduce CI from scratch: `rm -rf .terraform && terraform init`.
* Same idea for providers: the lock file. For modules there is no lock file - the ref is the lock.
