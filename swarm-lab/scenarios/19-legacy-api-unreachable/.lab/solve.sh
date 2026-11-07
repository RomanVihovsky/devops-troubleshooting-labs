dk stack rm "$STACK" >/dev/null
retry 90 sh -c '[ -z "$(docker exec lab-manager1 docker network ls -q --filter name=app_appnet)" ]'
ws_sed 's#subnet: 172.30.0.0/16.*#subnet: 10.123.0.0/24#'
deploy_stack
retry 90 svc_converged app_billing
