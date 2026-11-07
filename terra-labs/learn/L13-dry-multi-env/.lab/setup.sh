run_logged "$SETUP_LOG" tg live/dev/web backend bootstrap
for u in dev/web prod/web prod/audit; do
  run_logged "$SETUP_LOG" tg "live/$u" apply -auto-approve -input=false -no-color
done
remember prod_ctime "$(aws s3api list-buckets --query "Buckets[?Name=='acme-prod-web-assets'].CreationDate" --output text)"
remember dev_ctime "$(aws s3api list-buckets --query "Buckets[?Name=='acme-dev-web-assets'].CreationDate" --output text)"
