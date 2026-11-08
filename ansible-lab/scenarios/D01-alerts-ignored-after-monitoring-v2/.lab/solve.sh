sed -i 's|condition: event.payload.check == "nginx" and event.payload.status == "down"|condition: event.payload.alert.check == "nginx" and event.payload.alert.state == "critical"|' rulebooks/web.yml
sed -i "s|^  hosts: .*|  hosts: \"{{ ansible_eda.event.payload.alert.target.fqdn \| split('.') \| first }}\"|" remediate/nginx.yml
grep -q 'alert.state == "critical"' rulebooks/web.yml
eda_restart /work
eda_post "$(cat docs/alerts/v2-nginx-critical.json)"
retry 60 svc_active web3 nginx
