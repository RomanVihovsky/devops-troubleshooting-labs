cat >> bootstrap/main.tf <<'TF'

resource "aws_s3_bucket" "state" {
  bucket = "acme-tfstate"
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
TF
apply bootstrap
sed -i 's|  # TODO: backend "s3" - partial configuration, the settings go to backend.hcl|  backend "s3" {}|' inventory/versions.tf
cat > inventory/backend.hcl <<'TF'
bucket       = "acme-tfstate"
key          = "inventory/terraform.tfstate"
region       = "eu-central-1"
use_lockfile = true
TF
run_logged "$SETUP_LOG" tf inventory init -migrate-state -force-copy -backend-config=backend.hcl -input=false -no-color
rm -f inventory/terraform.tfstate inventory/terraform.tfstate.backup
run_logged "$SETUP_LOG" tf inventory apply -auto-approve -input=false -no-color
