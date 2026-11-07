# Security scan: staging app runs inside the PROD VPC
**SEC-355** · P1 · Reporter: security team

The network scan found security group `staging-app` attached to the **prod** VPC (`10.25.0.0/16`) -
staging workloads can reach prod databases. `live/staging/app` was created from a copy of prod's unit.
Staging has its own network (`10.26.0.0/16`).

Fix the wiring. Prod must not be touched.

**Test**: `staging-app` lives in the staging VPC and its config points at staging's subnet; prod's security
group is the original; `terragrunt run --all plan` in `live/` shows no changes.
