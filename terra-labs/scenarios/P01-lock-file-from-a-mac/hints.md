## Hint 1
`git show HEAD -- stacks/config-bundle/.terraform.lock.hcl`. How many `h1:` hashes per provider, and for
which platform? A lock file records hashes per platform; a package for another platform has a different hash.

## Hint 2
Deleting the lock file or `-upgrade` would silently move versions. The tool for adding platforms is
`terraform providers lock -platform=... -platform=...`. It normally asks the public registry; point it at
the mirror with `-fs-mirror=$TERRALAB_PROVIDER_MIRROR`.

## Hint 3
`terraform providers lock -fs-mirror="$TERRALAB_PROVIDER_MIRROR" -platform=linux_amd64 -platform=darwin_arm64`,
`terraform init`, `terraform plan`, then commit the lock file.
