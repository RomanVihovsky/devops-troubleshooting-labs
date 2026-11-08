ap site.yml
ws_commit "sshd hardening"
sed -i 's/MaxAuthTries: "4"/MaxAuthTries: "3"/; s/ClientAliveInterval: "600"/ClientAliveInterval: "300"/' group_vars/all.yml
ws_commit "security: MaxAuthTries 3, ClientAliveInterval 300 (SEC-79)" "security team"
ap site.yml
