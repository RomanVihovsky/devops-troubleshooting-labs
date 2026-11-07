aws s3api create-bucket --bucket acme-tfstate --create-bucket-configuration LocationConstraint=eu-central-1 >/dev/null
aws s3api put-bucket-versioning --bucket acme-tfstate --versioning-configuration Status=Enabled
apply stacks/catalog-api
remember ctime "$(aws s3api list-buckets --query "Buckets[?Name=='acme-catalog-api-data'].CreationDate" --output text)"
