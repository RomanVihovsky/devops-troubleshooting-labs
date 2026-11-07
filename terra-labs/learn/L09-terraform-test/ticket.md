# L09 · terraform test: unit tests, mocks and integration
**Learn** · .tftest.hcl, run blocks, expect_failures, mock_provider, override_resource · ~30 min

Two modules have no tests. Write them with `terraform test` - and make them **mean it**: the lab
will break the modules on purpose and expects your tests to go red.

1. `modules/naming` (pure logic). In `modules/naming/tests/naming.tftest.hcl` (`command = plan`):
   - staging + team `payments` + name `invoices` -> `bucket_name == "acme-staging-payments-invoices"`
     and `tags.team == "payments"`;
   - `env = "qa"` is rejected -> `expect_failures = [var.env]`.
2. `modules/bucket` (AWS). Unit test **without AWS** in `tests/unit.tftest.hcl`: `mock_provider "aws"`
   plus `override_resource` so that `aws_s3_bucket.this` gets `arn = "arn:aws:s3:::unit-bucket"`;
   assert the module's `arn` output.
3. Integration test against the lab's fake AWS in `tests/integration.tftest.hcl` (`command = apply`):
   assert the bucket's versioning status is `"Enabled"`. Terraform destroys it again afterwards.
4. `terraform init && terraform test` in each module -> all green.

**Test**: `terraform test` passes in both modules; tests include `expect_failures`, a `mock_provider`
and an `apply` run; when the lab breaks the name format, the naming tests fail; when it disables
versioning, the integration test fails; when it breaks the arn output, the unit test fails.
