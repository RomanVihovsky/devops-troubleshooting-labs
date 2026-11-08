ap site.yml
ws_commit "appserver role"
echo 'appserver_workers: 8   # load test findings (LT-12)' > group_vars/web.yml
ws_commit "web: 8 workers" "Kim (web)"
ap site.yml
