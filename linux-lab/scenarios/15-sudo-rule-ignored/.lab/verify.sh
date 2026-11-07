check "visudo -c passes" sx 'visudo -c -q'
check "deploy: sudo -n systemctl restart nginx works" as_user deploy 'sudo -n systemctl restart nginx'
check "deploy: sudo -n id is still refused" as_user deploy '! sudo -n id 2>/dev/null'
verdict
