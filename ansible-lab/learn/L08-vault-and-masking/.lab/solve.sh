printf '#!/bin/sh\n# vault password client: the secret comes from the environment (CI secret store / your shell)\necho "$ACME_VAULT_PROD"\n' > vault-pass.sh
chmod +x vault-pass.sh
sed -i '/^# TODO: encrypt me/d' group_vars/web/vault.yml
sed -i 's|^interpreter_python = auto_silent|interpreter_python = auto_silent\nvault_identity_list = prod@vault-pass.sh|' ansible.cfg
run_logged "$SETUP_LOG" ctl "ansible-vault encrypt --encrypt-vault-id prod group_vars/web/vault.yml"
python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = s.replace("""      register: token_raw
""", """      register: token_raw
      no_log: true
""")
s = s.replace("""        api_token: "{{ token_raw.content | b64decode | trim }}\"""", """        api_token: "{{ (token_raw.content | b64decode | trim) | ansible.builtin.register_secret }}\"""")
s = s.replace("""        mode: "0600"
""", """        mode: "0600"
      diff: false
""")
open(p, "w").write(s)
PY
ap site.yml
