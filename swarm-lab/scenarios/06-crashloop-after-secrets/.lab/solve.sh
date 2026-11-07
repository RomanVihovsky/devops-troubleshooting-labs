ws_sed 's#REDIS_PASSWORD_FILE: /run/secrets/redis_password#REDIS_PASSWORD_FILE: /run/secrets/redis_pw#'
deploy_stack
retry 90 svc_converged app_web
