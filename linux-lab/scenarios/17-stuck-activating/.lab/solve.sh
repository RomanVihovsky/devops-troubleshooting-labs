sx "sed -i 's/^Type=forking/Type=simple/; /^PIDFile=/d' /etc/systemd/system/cachewarm.service && systemctl daemon-reload && systemctl restart cachewarm"
