# CI plan shows changes nobody made - locally the plan is clean
**INFRA-255** · P2 · Reporter: storefront team

The nightly CI plan of `stacks/storefront` suddenly shows `1 to add, 1 to change`: the log level
parameter goes from `info` to `warn` and a new parameter appears. Nobody committed anything to our repo
for two weeks, and on my laptop `terraform plan` says "No changes". Prod runs the module version we
reviewed in September (v1.2.0).

Make the stack deterministic: what is deployed must not change unless our repo changes.

**Test**: a CI plan (fresh checkout) shows no changes; the module is pinned to an immutable ref of what is
deployed (tag `v1.2.0` or its commit); the deployed values are unchanged.
