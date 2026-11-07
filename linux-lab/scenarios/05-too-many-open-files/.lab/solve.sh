sx "mkdir -p /etc/systemd/system/catalog-api.service.d && printf '[Service]\nLimitNOFILE=65535\n' > /etc/systemd/system/catalog-api.service.d/zz-nofile.conf && systemctl daemon-reload && systemctl restart catalog-api"
sleep 2
