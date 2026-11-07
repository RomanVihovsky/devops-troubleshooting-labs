d=secrets
st=checkout-secrets/terraform.tfstate
key=$(recall key)
pw=$(ssm_value /checkout/db/password || true)
pw_ok() {
  [ ${#pw} -ge 24 ] &&
    [ "$(aws ssm get-parameter --name /checkout/db/password --query Parameter.Type --output text)" = SecureString ]
}
key_ok() {
  [ "$(aws secretsmanager get-secret-value --secret-id checkout/partner-api-key --query SecretString --output text 2>/dev/null)" = "$key" ]
}
not_in_state() { [ -n "$1" ] && s3_cat acme-tfstate $st >/dev/null && not_in_s3_object acme-tfstate $st "$1"; }
ephemeral_var() {
  # behaviour, not syntax: a root output of the variable must be rejected
  ci_init $d || return 1
  printf 'output "lab_probe" {\n  value     = var.partner_api_key\n  sensitive = true\n}\n' > "$CI/$d/zz_lab_probe.tf"
  local rc=0
  ci_tf $d validate -no-color > "$CI/probe.out" 2>&1 || rc=$?
  cat "$CI/probe.out" >> "$VERIFY_LOG"
  rm -f "$CI/$d/zz_lab_probe.tf"
  [ $rc -ne 0 ] && grep -qi 'ephemeral' "$CI/probe.out"
}
check "SSM /checkout/db/password: SecureString, 24+ chars" pw_ok
check "Secrets Manager checkout/partner-api-key holds the vendor key" key_ok
check "DB password is not in the state" not_in_state "$pw"
check "API key is not in the state" not_in_state "$key"
check "partner_api_key is ephemeral (a root output of it is rejected)" ephemeral_var
check "CI plan shows no changes" plan_clean $d
verdict
