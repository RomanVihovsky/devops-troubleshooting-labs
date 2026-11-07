sx "sed -i 's/^Options=.*/Options=bind,nosuid,nodev/' /etc/systemd/system/opt-tools.mount && systemctl daemon-reload && systemctl restart opt-tools.mount"
