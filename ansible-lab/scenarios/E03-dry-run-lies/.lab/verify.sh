predicts_upgrade() {
  ap_json site.yml --check -e app_version=9.9.9 && stats_ok '.failures == 0' && task_not_skipped "Stop the app for the upgrade"
}
check "check mode passes with no changes (converged node)" converged site.yml
check "check mode predicts the restart for app_version=9.9.9" predicts_upgrade
check "app1 untouched by dry runs (1.0.0, running)" eval 'nx app1 "grep -qx 1.0.0 /opt/app/VERSION && systemctl is-active --quiet acme-app"'
check "no ignore_errors in the repo" not ws_has 'ignore_errors'
check "the real deploy works" applies site.yml
verdict
