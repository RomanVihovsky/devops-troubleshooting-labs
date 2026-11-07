sx "sed -i 's/^reap_children = no/reap_children = yes/' /etc/report-worker.conf && systemctl restart report-worker"
sleep 2
