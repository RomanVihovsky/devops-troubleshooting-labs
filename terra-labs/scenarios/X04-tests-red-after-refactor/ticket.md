# main is red: terraform test fails after "simplify pricing"
**INFRA-320** · P2 · Reporter: CI

After merging "refactor: simplify pricing module" (reviewed in a hurry), `terraform test` in
`modules/pricing` fails on main. The author says "the tests are too strict, just update the expected
numbers". Finance disagrees.

Make main green **without changing the tests**. Keep the refactor's intent where it is correct.

**Test**: `terraform test` passes in `modules/pricing`; `tests/` is unchanged.
