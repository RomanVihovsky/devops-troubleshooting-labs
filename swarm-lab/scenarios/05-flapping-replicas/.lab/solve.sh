ws_sed 's#"curl", "-fsS"#"wget", "-qO-"#'
deploy_stack
retry 90 svc_converged app_web
