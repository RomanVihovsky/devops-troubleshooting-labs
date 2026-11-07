dk tag lab/report-api:1.4 registry:5000/lab/report-api:1.4
dk push -q registry:5000/lab/report-api:1.4 >/dev/null
ws_sed 's#image: lab/report-api:1.4#image: registry:5000/lab/report-api:1.4#'
deploy_stack
retry 90 svc_converged app_api
