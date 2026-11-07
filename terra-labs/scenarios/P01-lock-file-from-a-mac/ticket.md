# CI: "doesn't match any of the checksums previously recorded in the dependency lock file"
**INFRA-236** · P2 · Reporter: CI

Since yesterday `terraform init` fails in the pipeline for `stacks/config-bundle`:
`the current package for registry.terraform.io/hashicorp/random 3.9.1 doesn't match any of the
checksums previously recorded in the dependency lock file`. The last commit came from a developer
working on an Apple Silicon Mac. Proposed fixes in the channel: "delete the lock file", "`init -upgrade`".

CI runs on `linux_amd64`, developers on `linux_amd64` and `darwin_arm64`. Provider versions must stay
exactly as they are. The company provider mirror is at `$TERRALAB_PROVIDER_MIRROR`.

**Test**: a CI `init` + plan works and shows no changes; the committed lock file has hashes for both
linux_amd64 and darwin_arm64 and still pins random 3.9.1 / local 2.9.1.
