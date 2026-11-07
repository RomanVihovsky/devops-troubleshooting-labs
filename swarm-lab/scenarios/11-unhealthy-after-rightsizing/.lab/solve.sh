ws_sed 's/cpus: "0.02"/cpus: "0.5"/'
deploy_stack
retry 120 svc_converged app_web
