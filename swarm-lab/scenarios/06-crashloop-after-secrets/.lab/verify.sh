uses_secret() { dk service inspect -f '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' app_web | grep -q redis_pw; }
check_eventually 60 "app_web is 2/2" svc_converged app_web
check "no task replaced for 15 s" svc_stable app_web 15
check "web still gets the password from the secret" uses_secret
check_eventually 20 "web answers with hits= via every node" all_nodes_http / 'hits='
verdict
