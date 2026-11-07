sx "sed -i 's/^hosts:.*/hosts:          files dns myhostname/' /etc/nsswitch.conf && grep -v 'api.internal' /etc/hosts > /tmp/h && cat /tmp/h > /etc/hosts"
