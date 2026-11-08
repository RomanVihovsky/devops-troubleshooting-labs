job=$RANDOM
ci_run() { ctl_ci "CI_JOB_ID=$job ci/deploy.sh" >> "$VERIFY_LOG" 2>&1; }
deployed() { [ "$(nx web1 'cat /etc/acme/deploy-id')" = "$job" ] && [ "$(nx web2 'cat /etc/acme/deploy-id')" = "$job" ]; }
not_ww() { [ "$(docker exec "$CTL" stat -c %A "/tmp/ci-build-$job" | cut -c9)" != w ]; }
check "ci/deploy.sh runs green on a fresh checkout" ci_run
check "...and deployed the job ID to both web nodes" deployed
check "the CI build directory is not world-writable" not_ww
verdict
