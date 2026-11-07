nsh worker2 'jq ".\"insecure-registries\" = [\"registry:5000\"]" /etc/docker/daemon.json > /tmp/d.json &&
             cat /tmp/d.json > /etc/docker/daemon.json && kill -HUP $(pidof dockerd)'
retry 90 svc_on_all_nodes app_agent 3
