nsh worker1 'iptables -t raw -D OUTPUT -d 172.30.0.11 -p tcp --dport 2377 -j DROP'
retry 120 sh -c "docker exec lab-manager1 docker node ls --format '{{.Hostname}} {{.Status}}' | grep -q 'worker1 Ready'"
