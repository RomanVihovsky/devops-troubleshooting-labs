deploy_stack
retry 90 svc_converged app_web
retry 90 svc_converged app_proxy
retry 60 all_nodes_http / 'Hello' 1
force_update app_web          # the "routine redeploy"
sleep 2
