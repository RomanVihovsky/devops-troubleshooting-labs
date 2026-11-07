ws_sed '0,/networks: \[frontend\]/s//networks: [frontend, backend]/'
deploy_stack
retry 60 svc_converged app_web
