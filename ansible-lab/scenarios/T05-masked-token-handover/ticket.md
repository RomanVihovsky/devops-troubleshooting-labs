# Smoke test fails with 401 since the runner moved to ansible-core 2.22
**OPS-270** · P2 · Reporter: CI

`ci/pipeline.sh` deploys the API gateway, then the smoke test calls `/api/health` with the token. Since the
runner image moved to 2.22 the deploy is green but the smoke test gets **401**. In the deploy log the token
handed over to the smoke test reads `$REDACTED$`.

The token stays in vault. Security's rule: secrets never appear in CI logs - in any encoding.

**Test**: `ci/pipeline.sh` passes; the token (plain or base64) is not in its output; any file holding the token
in the checkout is mode 0600 and not committed; the vault file stays encrypted.
