# Solution - masked secrets: hand over via a 0600 file, not stdout

**Root cause**: ansible-core 2.22 masks known secrets (vault values, `no_log` parameters, values registered
with `register_secret`) as `$REDACTED$` in every output, `debug` included. The pipeline scraped the token
from the deploy log - it now gets `$REDACTED$` -> 401. Scraping it ever worked only because the token leaked
into every CI log.

**Fix**: write it to `.ci/smoke-token` (`copy`, `mode: "0600"`, git-ignored) from the localhost play; the
pipeline reads the file and deletes it after the smoke test. Rotate the token - it sat in old CI logs.

**Interview notes**
* Masking is non-destructive: the real value still reaches modules and files - only display is masked.
* `no_log: true` hides a whole task result; `register_secret` marks a computed value as secret (2.22).
* Base64, `reverse`, slicing... are still leaks: the guard here checks plain and base64.
* `ansible-playbook` output in CI = logs kept for months, visible to everyone with read access.
