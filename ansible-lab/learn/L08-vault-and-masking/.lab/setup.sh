pw="db-$(head -c 9 /dev/urandom | od -An -tx1 | tr -d ' \n')"
remember dbpw "$pw"
printf '# TODO: encrypt me (vault id: prod)\nvault_app_db_password: %s\n' "$pw" > group_vars/web/vault.yml
lab_setenv ACME_VAULT_PROD "vault-$(head -c 9 /dev/urandom | od -An -tx1 | tr -d ' \n')"
for n in web1 web2; do
  t="tok-$n-$(head -c 9 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  remember "tok.$n" "$t"
  nx $n "mkdir -p /etc/acme && echo $t > /etc/acme/bootstrap-token && chmod 600 /etc/acme/bootstrap-token"
done
