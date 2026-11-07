cache_kept() { dk service inspect -f '{{json .Spec.TaskTemplate.ContainerSpec.Env}}' app_web | grep -q 'CACHE_WARMUP_MB=192"'; }
check_eventually 45 "app_web is 2/2" svc_converged app_web
check "no task replaced for 15 s" svc_stable app_web 15
check "CACHE_WARMUP_MB is still 192" cache_kept
check_eventually 20 "web answers via every node" all_nodes_http / 'Hello'
verdict
