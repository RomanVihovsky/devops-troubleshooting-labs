printf '#!/bin/sh\necho "$ACME_VAULT_PROD"\n' > vault-pass.sh && chmod +x vault-pass.sh
sed -i 's|^interpreter_python = auto_silent|interpreter_python = auto_silent\nvault_identity_list = prod@vault-pass.sh|' ansible.cfg
printf 'vault_become_password: %s\n' "$ACME_BECOME_PASSWORD" > group_vars/all/vault.yml
echo 'ansible_become_password: "{{ vault_become_password }}"' > group_vars/all/vars.yml
run_logged "$SETUP_LOG" ctl "ansible-vault encrypt --encrypt-vault-id prod group_vars/all/vault.yml"
ap site.yml
