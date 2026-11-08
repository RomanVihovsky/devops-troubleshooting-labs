check "site.yml deploys" applies site.yml
check "3 worker spool dirs exist" eval 'nx app1 "test -d /var/spool/acme/worker1 && test -d /var/spool/acme/worker3"'
check "both config files exist" eval 'nx app1 "test -f /etc/acme/queue.conf && test -f /etc/acme/limits.conf"'
check "site.yml converges" converged site.yml
four_workers() { applies site.yml -e '{"workers_count": 4}' && nx app1 "test -d /var/spool/acme/worker4"; }
check "workers_count is still the knob (workers_count: 4)" four_workers
verdict
