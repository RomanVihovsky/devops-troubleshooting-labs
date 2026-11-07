# Staging apply created prod-* resources (and staging's are gone)
**INFRA-215** · P1 · Reporter: QA

Since this morning's staging deploy the staging services can't find their config: the parameters under
`/staging/web/...` and the topic `staging-web-events` are gone - instead there are `/prod/web/...`
parameters and a `prod-web-events` topic **in the staging account**. `stacks/web-config/terraform.tfvars`
clearly says `env = "staging"`. Nobody ran anything by hand.

**Test**: the staging parameters and topic are back; no prod-* resources exist; nothing in the stack can
override `env` silently any more; a CI plan shows no changes.
