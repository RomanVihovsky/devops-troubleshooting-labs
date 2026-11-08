# Security: new employees' initial passwords are readable in the deploy log
**SEC-93** · P1 · Reporter: security

The onboarding play creates accounts from the HR export (`.onboarding/users.json`, dropped on the runner by
the HR job - never committed). Security found the initial passwords in plain text in yesterday's
`ci/deploy.sh` log. "But ansible-core 2.22 masks secrets!" - apparently not these.

**Test**: `ci/deploy.sh` (and a JSON-callback run) contain none of the passwords; the accounts exist and accept
their initial passwords; site.yml converges.
