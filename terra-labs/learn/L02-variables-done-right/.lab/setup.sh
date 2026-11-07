token="tok_$(head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n')"
lab_setenv TF_VAR_api_token "$token"
remember token "$token"
