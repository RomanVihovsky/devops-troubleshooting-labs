aws s3api create-bucket --bucket acme-tfstate --create-bucket-configuration LocationConstraint=eu-central-1 >/dev/null
aws s3api put-bucket-versioning --bucket acme-tfstate --versioning-configuration Status=Enabled
apply secrets
key="pk_live_$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')"
lab_setenv TF_VAR_partner_api_key "$key"
remember key "$key"
