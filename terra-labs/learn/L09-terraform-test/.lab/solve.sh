cat > modules/naming/tests/naming.tftest.hcl <<'TF'
variables {
  team = "payments"
  name = "invoices"
}

run "staging_names" {
  command = plan

  variables {
    env = "staging"
  }

  assert {
    condition     = output.bucket_name == "acme-staging-payments-invoices"
    error_message = "unexpected bucket name ${output.bucket_name}"
  }

  assert {
    condition     = output.tags.team == "payments"
    error_message = "team tag missing"
  }
}

run "rejects_unknown_env" {
  command = plan

  variables {
    env = "qa"
  }

  expect_failures = [var.env]
}
TF
cat > modules/bucket/tests/unit.tftest.hcl <<'TF'
mock_provider "aws" {}

override_resource {
  target = aws_s3_bucket.this
  values = {
    arn = "arn:aws:s3:::unit-bucket"
  }
}

run "arn_output" {
  command = apply

  variables {
    bucket_name = "unit-bucket"
  }

  assert {
    condition     = output.arn == "arn:aws:s3:::unit-bucket"
    error_message = "arn output is ${output.arn}"
  }
}
TF
cat > modules/bucket/tests/integration.tftest.hcl <<'TF'
provider "aws" {
  region = "eu-central-1"
}

run "versioned_bucket" {
  command = apply

  variables {
    bucket_name = "acme-test-integration"
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "versioning is not enabled"
  }
}
TF
for m in modules/naming modules/bucket; do
  run_logged "$SETUP_LOG" terraform -chdir="$m" init -input=false -no-color
  run_logged "$SETUP_LOG" terraform -chdir="$m" test -no-color
done
