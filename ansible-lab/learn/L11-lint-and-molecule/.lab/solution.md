# Solution - L11

Reference: `.lab/solve.sh`.

**Takeaways**
* ansible-lint profiles: `min` < `basic` < `moderate` < `safety` < `shared` < `production`. Fix findings;
  `skip_list` is for rules your org rejected, not for today's red build. `--offline` for air-gapped runners.
* Molecule 26: drivers are optional - the `default` driver with `managed: false` tests against hosts you
  already have (VMs, a lab node, a cloud instance); `test_sequence` picks the steps.
* `idempotence` runs converge twice and fails on any `changed` - the cheapest quality gate there is.
* A verifier must test the *effect* (`sshd -T`), not the file you just wrote.
* The lab broke the role on purpose and expected molecule to go red - tests that cannot fail are decoration.
