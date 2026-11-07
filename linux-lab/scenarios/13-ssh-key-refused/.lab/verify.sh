check "StrictModes is still on" sx 'sshd -T 2>/dev/null | grep -qi "^strictmodes yes"'
check "ci@client can ssh deploy@srv with its key" cx 'su - ci -c "ssh -o BatchMode=yes -o ConnectTimeout=5 deploy@10.77.0.10 true"'
verdict
