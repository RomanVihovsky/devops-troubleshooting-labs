d=stacks/logs
# prod's current access-block keys, for the moved blocks
mapfile -t old < <(tf $d state list | sed -n 's/^aws_s3_bucket_public_access_block\.logs\["\(.*\)"\]$/\1/p')
python3 - <<'PY'
p = "stacks/logs/main.tf"
s = open(p).read()
s = s.replace('''  for_each = toset(aws_s3_bucket.logs[*].bucket)

  bucket                  = each.key''', '''  for_each = toset(var.log_buckets) # static keys: known before apply

  bucket                  = aws_s3_bucket.logs[index(var.log_buckets, each.key)].id''')
open(p, "w").write(s)
PY
for b in "${old[@]}"; do
  purpose=$(echo "$b" | sed -E 's/^acme-[a-z]+-([a-z]+)-logs-.*/\1/')
  printf '\nmoved {\n  from = aws_s3_bucket_public_access_block.logs["%s"]\n  to   = aws_s3_bucket_public_access_block.logs["%s"]\n}\n' "$b" "$purpose" >> $d/moved.tf
done
run_logged "$SETUP_LOG" tf $d apply -auto-approve -input=false -no-color -var-file=env/prod.tfvars
run_logged "$SETUP_LOG" tf $d init -reconfigure -input=false -no-color -backend-config=env/dr.s3.tfbackend
run_logged "$SETUP_LOG" tf $d apply -auto-approve -input=false -no-color -var-file=env/dr.tfvars
