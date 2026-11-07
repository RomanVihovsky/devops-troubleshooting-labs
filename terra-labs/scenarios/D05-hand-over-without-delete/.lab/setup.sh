state_bucket
cat >> stacks/platform-shared/main.tf <<'TF'

resource "aws_s3_bucket" "datasets" {
  bucket = "acme-ml-datasets"
}

resource "aws_s3_bucket_versioning" "datasets" {
  bucket = aws_s3_bucket.datasets.id
  versioning_configuration {
    status = "Enabled"
  }
}
TF
apply stacks/platform-shared
echo 'img,label' | aws s3 cp - s3://acme-ml-datasets/v3/train.csv >/dev/null
remember_bucket acme-ml-datasets
ws_commit "platform-shared: alerts, artifacts, ML datasets"
cp "$SCN/files/stacks/platform-shared/main.tf" stacks/platform-shared/main.tf
ws_commit "hand acme-ml-datasets over to the data team" "Morgan (platform)"
