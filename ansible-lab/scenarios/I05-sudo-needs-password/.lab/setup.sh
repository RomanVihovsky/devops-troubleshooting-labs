ap site.yml
ws_commit "web baseline"
pw="Bp-$(head -c 9 /dev/urandom | od -An -tx1 | tr -d ' \n')"
remember becomepw "$pw"
lab_setenv ACME_BECOME_PASSWORD "$pw"
lab_setenv ACME_VAULT_PROD "vault-$(head -c 9 /dev/urandom | od -An -tx1 | tr -d ' \n')"
for n in web1 web2; do
  nx $n "echo 'ansible:$pw' | chpasswd && echo 'ansible ALL=(ALL) ALL' > /etc/sudoers.d/ansible && chmod 0440 /etc/sudoers.d/ansible"
done
