# Renovate PR breaks init: "no available releases match the given constraints"
**INFRA-241** · P2 · Reporter: platform

Renovate bumped `tf-module-topic` from v1.3.0 to v1.4.0 in `stacks/events` (v1.4.0 adds KMS encryption,
which security asked for). Now `terraform init` fails: no version of `hashicorp/aws` matches the
given constraints. Our root module requires AWS provider 6.x and that is not negotiable.

Get onto a module version with encryption that works with provider 6. The topics have subscribers -
they must not be recreated. Read the module's CHANGELOG.

**Test**: CI init + plan work and show no changes; the module comes from a tag >= v2.0.0; both topics are
encrypted with KMS; their subscriptions survived (not recreated).
