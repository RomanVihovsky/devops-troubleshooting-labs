# Security change broke the prod pipeline: "dependency cycle"
**SEC-361** · P1 · Reporter: platform on-call

Security wanted the database security group to accept Postgres **only** from the app tier, so the
network unit now reads the app's security group ID. Since that merge `terragrunt run --all plan` in
`live/prod` refuses to run: it found a dependency cycle between `network` and `app`.

Deliver the security requirement without a cycle. The database security group must not be replaced.

**Test**: the db security group allows 5432 from the app security group; the DAG has no cycle;
the db security group is the original; `terragrunt run --all plan` in `live/prod` shows no changes.
