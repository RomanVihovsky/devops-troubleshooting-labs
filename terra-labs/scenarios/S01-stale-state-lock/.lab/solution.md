# Solution - stale S3 lockfile from a killed CI job

**Root cause**: with `use_lockfile = true` the S3 backend writes `<key>.tflock` next to the state
(a conditional `PutObject` with `If-None-Match: *`) and deletes it when the run ends. The runner was
SIGKILLed (OOM) mid-apply, so nothing deleted it. Every later run sees the object and gives up.

**Diagnose**
```
cd stacks/payments && terraform init
terraform plan                       # Lock Info: ID, Who: gitlab-runner@ci-runner-07, Created: yesterday 02:13
aws s3 ls s3://acme-tfstate --recursive          # payments/terraform.tfstate.tflock
aws s3 cp s3://acme-tfstate/payments/terraform.tfstate.tflock -
```
Owner is provably dead (runner recycled, lock is hours old, no pipeline running) -> safe to break.

**Fix**: `terraform force-unlock <ID>` (it refuses if the ID does not match the current lock, which
protects you from breaking a *new* lock by mistake). Then `terraform plan` -> No changes.
Deleting the `.tflock` object by hand works too, but has no such ID check.

**Interview notes**
* Locks protect against two writers: lost updates, interleaved state serials, orphaned resources.
  `-lock=false` trades a visible error for invisible corruption.
* Since TF 1.10 the S3 backend locks natively (`use_lockfile`); `dynamodb_table` is deprecated (TF 1.11).
  During migration both can be enabled at once.
* If the killed run was mid-apply, the state may already contain partial results (state is saved
  periodically): after unlocking, `plan` tells you what is left to do - do not restore an old state.
* `-lock-timeout=5m` in CI makes concurrent pipelines wait instead of failing.
* Prevent: give CI jobs enough memory, serialize applies per state (one pipeline/state), alert on locks
  older than N hours.
