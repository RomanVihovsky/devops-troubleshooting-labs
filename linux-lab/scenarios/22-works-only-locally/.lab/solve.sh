sx "iptables -D INPUT -p tcp --dport 8090 -j DROP; sed -i 's/^bind = .*/bind = 0.0.0.0/' /etc/metrics-api.conf && systemctl restart metrics-api"
sleep 1
