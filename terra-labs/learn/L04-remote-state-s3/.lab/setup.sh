apply inventory
# identity of the real resources: a migration must not recreate them
remember bucket_ctime "$(aws s3api list-buckets --query "Buckets[?Name=='acme-inventory-exports'].CreationDate" --output text)"
remember params_mtime "$(aws ssm get-parameters-by-path --path /inventory/warehouses --query 'sort_by(Parameters,&Name)[].LastModifiedDate' --output text)"
