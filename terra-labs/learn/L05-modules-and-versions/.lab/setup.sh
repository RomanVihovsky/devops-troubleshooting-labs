publish tf-module-bucket v1.0.0 "$LAB_DIR/learn/L05-modules-and-versions/.lab/modules/v1.0.0" "initial release"
publish tf-module-bucket v1.1.0 "$LAB_DIR/learn/L05-modules-and-versions/.lab/modules/v1.1.0" "feat: default encryption"
aws s3api create-bucket --bucket acme-tfstate --create-bucket-configuration LocationConstraint=eu-central-1 >/dev/null
aws s3api put-bucket-versioning --bucket acme-tfstate --versioning-configuration Status=Enabled
apply stacks/media
echo 'png' | aws s3 cp - s3://acme-media-assets/products/1001.png >/dev/null
remember ctime "$(aws s3api list-buckets --query "Buckets[?Name=='acme-media-assets'].CreationDate" --output text)"
