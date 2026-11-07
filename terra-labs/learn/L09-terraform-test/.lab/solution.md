# Solution - L09

Reference tests: `.lab/solve.sh`.

**Takeaways**
* `terraform test` (1.6+) runs `run` blocks in order, sharing state within a file, and destroys what
  `command = apply` created at the end. `command = plan` = fast unit tests, no infrastructure.
* `expect_failures` turns "this must be rejected" into a passing test (validations, pre/postconditions,
  check blocks).
* `mock_provider` (1.7+) returns fake values for computed attributes; `override_resource`,
  `override_data`, `override_module` pin the ones you assert on. Since 1.15 mock blocks may use functions.
* Tests are only worth something if they fail when the code is wrong. That is what the lab checked
  with **mutants** - a cheap form of mutation testing you can script in CI too.
* Put integration runs in their own file so CI can run units on every push and
  `-filter=tests/integration.tftest.hcl` nightly.
