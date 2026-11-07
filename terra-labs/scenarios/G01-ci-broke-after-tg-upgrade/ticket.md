# Every Terragrunt pipeline is red since the runner image upgrade
**INFRA-281** · P1 · Reporter: CI

The CI runner image now ships Terragrunt 1.2. Since then `ci/plan-all.sh prod` fails immediately -
Terragrunt just prints its usage. Nothing else changed. Pinning the old Terragrunt is not an option
(security fixes).

**Test**: `ci/plan-all.sh prod` plans every unit of `live/prod` and exits 0; it still fails when a unit
fails; it uses the 1.x CLI only (no `run-all`, no `--terragrunt-*` flags, no `TERRAGRUNT_*` variables).
