# Solution - terragrunt backend bootstrap

**Root cause**: Terragrunt < 0.80/1.0 silently created missing S3 buckets (and DynamoDB tables). 1.x
requires an explicit `terragrunt backend bootstrap` (or `--backend-bootstrap`), so a new environment's
bucket simply does not exist.

**Fix**: `terragrunt backend bootstrap --all` in `live/staging`, then `run --all -- apply`. Bootstrap
applies the hardening Terragrunt knows from `remote_state.config` (versioning, SSE, public access block,
TLS-only policy - skipped here only because the fake AWS can't evaluate it).

**Interview notes**
* Explicit bootstrap = no surprise buckets in the wrong account because of a typo in `bucket`.
* `terragrunt backend migrate` moves state between units/backends; `backend delete` removes it.
* A hand-made bucket "works" but lacks versioning: the first bad `state push` (incident S03) is then fatal.
