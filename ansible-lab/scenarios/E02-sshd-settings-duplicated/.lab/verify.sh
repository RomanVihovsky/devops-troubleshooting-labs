effective() { nx web1 "sshd -T" | grep -ix "$1" >/dev/null; }
once() { local k; for k in PermitRootLogin MaxAuthTries ClientAliveInterval X11Forwarding; do
  [ "$(nx web1 "grep -hiE '^[[:space:]]*${k}[[:space:]]' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null | wc -l")" = 1 ] || { echo "$k not exactly once" >> "$VERIFY_LOG"; return 1; }
done; }
change_applies() {
  applies site.yml -e '{"sshd_settings": {"PermitRootLogin": "no", "MaxAuthTries": "2", "ClientAliveInterval": "300", "X11Forwarding": "no"}}' \
    && effective "maxauthtries 2" && applies site.yml && effective "maxauthtries 3"
}
check "site.yml runs" applies site.yml
check "sshd -T: permitrootlogin no, maxauthtries 3" eval 'effective "permitrootlogin no" && effective "maxauthtries 3"'
check "sshd -T: clientaliveinterval 300, x11forwarding no" eval 'effective "clientaliveinterval 300" && effective "x11forwarding no"'
check "each managed setting is defined exactly once" once
check "a changed value takes effect in one run" change_applies
check "site.yml converges" converged site.yml
verdict
