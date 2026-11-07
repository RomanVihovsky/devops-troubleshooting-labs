# Solution - lock hashes for every platform you run on

**Root cause**: `.terraform.lock.hcl` was regenerated on a Mac. It records the selected versions and
**package checksums** - only for `darwin_arm64`. The linux package CI downloads has a different hash,
so `init` refuses it (that is the lock file doing its job: supply-chain protection).

**Fix**
```
terraform providers lock -fs-mirror="$TERRALAB_PROVIDER_MIRROR" \
  -platform=linux_amd64 -platform=darwin_arm64
git add .terraform.lock.hcl && git commit
```
Versions stay; hashes for both platforms are recorded.

**Interview notes**
* From the public registry, `init` records `zh:` hashes for all platforms automatically; from a mirror
  (or cache) only `h1:` of the current platform -> run `providers lock` for every platform in the team.
* Deleting the lock file = unpinned versions on the next init; `init -upgrade` = new versions on purpose.
* Renovate/Dependabot can bump providers and regenerate locks for all platforms.
