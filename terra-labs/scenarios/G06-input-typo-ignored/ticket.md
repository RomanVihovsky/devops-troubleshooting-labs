# env.hcl says 3 replicas, staging runs with 1
**INFRA-301** · P3 · Reporter: QA (load tests keep failing)

`live/staging/env.hcl` sets `replicas = 3` - but `/staging/web/replicas` says `1` and every plan says
"No changes". No error, no warning anywhere.

**Test**: `/staging/web/replicas` is 3 and comes from `env.hcl` (not hard-coded); `terragrunt run --all plan`
shows no changes.
