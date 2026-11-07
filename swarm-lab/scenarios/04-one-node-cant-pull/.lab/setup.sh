# config-management run on worker2 templated an empty list (restored by ./lab reset).
# Note: on SIGHUP a *missing* key keeps the old value - an explicit [] really clears it.
nsh worker2 'jq ".\"insecure-registries\" = []" /usr/share/swarmlab/daemon.json > /etc/docker/daemon.json &&
             kill -HUP $(pidof dockerd) && sleep 1 &&
             docker images -q registry:5000/lab/webapp | sort -u | xargs -r docker rmi -f >/dev/null'
deploy_stack
