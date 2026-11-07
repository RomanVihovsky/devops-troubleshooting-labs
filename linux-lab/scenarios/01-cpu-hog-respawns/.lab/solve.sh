sx 'crontab -l | grep -v metrics-agent | crontab -'
sx 'pkill -f "^\[kmetricsd\]"; true'
