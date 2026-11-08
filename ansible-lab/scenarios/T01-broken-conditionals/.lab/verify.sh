tls_switch_works() { ap_json site.yml --check -e '{"enable_tls": false}' && task_skipped "TLS config"; }
tls_on_by_default() { converged site.yml && task_not_skipped "TLS config"; }
rejects_empty_name() { ! ap_json site.yml --check -e '{"app_name": ""}' && out_has "app_name and app_port must be set"; }
check "site.yml converges on ansible-core 2.22 (no errors, no changes)" converged site.yml
check "TLS task runs by default" tls_on_by_default
check "enable_tls: false really skips the TLS task" tls_switch_works
check "an empty app_name is still rejected by the validation" rejects_empty_name
check "ALLOW_BROKEN_CONDITIONALS is not used anywhere" no_broken_cond_escape
verdict
