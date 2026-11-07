key=notifications/terraform.tfstate
# versions come newest first: [0] is the forced push, [1] the state just before it
good=$(aws s3api list-object-versions --bucket acme-tfstate --prefix "$key" \
         --query "Versions[?Key=='$key'] | [1].VersionId" --output text)
aws s3api get-object --bucket acme-tfstate --key "$key" --version-id "$good" "$STATE_DIR/good.tfstate" >/dev/null
jq -e '[.resources[].type] | index("aws_iam_role")' "$STATE_DIR/good.tfstate" >/dev/null   # sanity check
run_logged "$SETUP_LOG" tf stacks/notifications init -input=false -no-color
run_logged "$SETUP_LOG" tf stacks/notifications state push -force "$STATE_DIR/good.tfstate"
