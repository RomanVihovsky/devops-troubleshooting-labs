# "Unsupported Terraform Core version" after vendoring the tags module
**INFRA-249** · P3 · Reporter: shop team

We copied the old `legacy-tags` module into `modules/` (the old repo is being archived). Since then
`terraform init` in `stacks/shop` fails with `Unsupported Terraform Core version`. Our pipelines run
Terraform 1.17. Somebody already suggested deleting the `required_version` line.

**Test**: CI init + plan show no changes; the module still declares a Terraform version constraint -
one that accepts 1.x from 1.9 on (incl. 1.17) but not 2.x.
