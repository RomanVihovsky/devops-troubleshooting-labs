# Plan wants to create things that exist - after someone "fixed" the state
**INFRA-131** · P1 · Reporter: notifications team

Yesterday two people applied `stacks/notifications` at the same time. One of them "fixed the conflict"
with `terraform state push -force` of a copy they had on their laptop. Today `terraform plan` wants to
**create** the refunds topic, the notifier role and a parameter - all of which exist and are in use.
Apply fails with "already exists" errors.

Don't import things by hand and don't recreate anything: get the state back to what it was.
The state bucket is versioned.

**Test**: a CI plan shows no changes; the refunds topic, the notifier role and the parameter are the
originals (not recreated or duplicated).
