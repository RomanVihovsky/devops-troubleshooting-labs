# L11 · ansible-lint and molecule
**Learn** · ansible-lint 26 (`production` profile), molecule 26 (default driver), idempotence, verify · ~30 min

`roles/sshd_hardening` works, but it would not survive code review, and it has no tests.

1. **Lint**: `ansible-lint --offline --profile production roles/sshd_hardening` - fix what it reports
   (FQCNs, task names, `yes`/`no`, file permissions, ...). Fix the code; don't add skip rules.
2. **Molecule**: create the scenario `roles/sshd_hardening/molecule/default/` that tests the role on the
   lab node **test1** (it already exists - use molecule's `default` driver with `managed: false` and an inventory
   pointing at `test1`, user `ansible`). Sequence: `syntax, converge, idempotence, verify`.
3. `verify.yml` must prove the hardening is **effective**: `sshd -T` reports `passwordauthentication no` and
   `permitrootlogin no`.
4. `cd roles/sshd_hardening && molecule test` -> green.

**Test**: lint (production profile) reports nothing; `molecule test` passes on a fresh checkout; the lab breaks
the role on purpose (non-idempotent task / hardening line removed) and molecule must catch both.
