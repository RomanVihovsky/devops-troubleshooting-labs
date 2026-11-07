has_healthcheck() { dk service inspect -f '{{json .Spec.TaskTemplate.ContainerSpec.Healthcheck.Test}}' app_web | grep -q health; }
check_eventually 60 "app_web is 3/3" svc_converged app_web
check "no task replaced for 20 s" svc_stable app_web 20
check "healthcheck still configured" has_healthcheck
check_eventually 20 "web answers via every node" all_nodes_http / 'Hello'
verdict
