ap site.yml
ws_commit "lb + web nodes, release 1.4.2"
# yesterday: the bad build everywhere at once, then the rollback
run_logged "$SETUP_LOG" ctl "ansible-playbook deploy.yml -e app_release=2.0.0-rc1" || true
ap deploy.yml -e app_release=1.4.2
retry 30 http_get http://lb1/version.txt    # wait until haproxy has all nodes back (rise 2)
